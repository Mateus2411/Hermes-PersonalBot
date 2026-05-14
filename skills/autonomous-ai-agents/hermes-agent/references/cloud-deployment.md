# Cloud Deployment

Provider-specific walkthroughs for running `hermes gateway run` on cloud platforms. Supplements the "Cloud Deployment" section in SKILL.md.

## Architecture Overview

```
                         ┌──────────────┐
                         │  Cloud Host   │  (Render / Railway / Fly.io / VPS)
                         │  ┌─────────┐  │
  Telegram ──webhook──▶  │  │ Gateway  │  │
  WhatsApp ◀──ws──────▶  │  │ Process  │  │
  Discord ◀──ws───────▶  │  │(hermes)  │  │
                         │  └────┬────┘  │
                         │       │       │
                         │  ┌────▼────┐  │
                         │  │Persistent│  │  /opt/data/
                         │  │ Volume   │  │  ├── config.yaml
                         │  └─────────┘  │  ├── .env
                         └──────────────┘  ├── gateway/whatsapp-auth/
                                            ├── sessions/
                                            ├── skills/
                                            └── logs/
```

### Model override — the `HERMES_MODEL` pitfall

The official Hermes Docker image ships with `cli-config.yaml.example` containing `model.default: "anthropic/claude-opus-4.6"` — a **paid model** on most providers. When a fresh container starts (no persistent disk, or first boot), it copies this template and the gateway will try to use `claude-opus-4.6`, which may fail with HTTP 401/"No payment method" if your provider doesn't have billing configured.

**Critical:** `HERMES_MODEL` and `HERMES_PROVIDER` env vars are **only read by the TUI subsystem** (the Ink/React terminal UI), **not by the gateway**. Setting them as plain env vars has no effect on which model the gateway uses. You must apply them to `config.yaml` after the entrypoint's bootstrap step.

**Fix — modify your entrypoint** (usually `docker/entrypoint.sh`):

```bash
# Add after the "Bootstrap config files" block:
if [ -n "${HERMES_MODEL:-}" ] || [ -n "${HERMES_PROVIDER:-}" ]; then
    python3 -c "
import yaml, os
path = '$HERMES_HOME/config.yaml'
with open(path) as f:
    cfg = yaml.safe_load(f)
changed = False
model_var = os.environ.get('HERMES_MODEL')
prov_var = os.environ.get('HERMES_PROVIDER')
if model_var:
    cfg.setdefault('model', {})['default'] = model_var
    changed = True
if prov_var:
    cfg.setdefault('model', {})['provider'] = prov_var
    changed = True
if changed:
    with open(path, 'w') as f:
        yaml.dump(cfg, f, default_flow_style=False)
    print(f'[config] model.default={model_var or \"(unchanged)\"}  provider={prov_var or \"(unchanged)\"}')
"
fi
```

Then set the env vars in your cloud platform (Render dashboard, Railway dashboard, `flyctl secrets set`, or `render.yaml`):

```yaml
# In render.yaml envVars:
- key: HERMES_MODEL
  value: "big-pickle"
- key: HERMES_PROVIDER
  value: "opencode-zen"
```

**Why this matters:** Without this step, every container restart on ephemeral storage will reset to the paid default model. The env var itself is inert for the gateway — you always need the entrypoint patching step.


### Render (render.com)

### Plan requirements

- **Starter ($7/mo)** — minimum viable. Includes 1GB persistent disk mounted anywhere.
- **Free tier** — no persistent disk, spins down after 15 min of inactivity **unless** you use the keep-alive trick below. WhatsApp pairing is lost on restart/deploy, but the app stays awake indefinitely if you ping its health endpoint externally.

### Render Free Tier — Keep-Alive Trick

Run Hermes on the **Render Free plan** 24/7 by adding a tiny health server alongside the gateway. An external cron (Google Apps Script) pings it every ~5 minutes → Render never detects inactivity → service never spins down.

**How it works:**
```
Google Apps Script ──ping every 5 min──▶ Render (health:10000)
                                             ├── Health server (stdlib Python)
                                             │   GET / → "ok | uptime: 0h 5m 23s"
                                             └── Hermes gateway (WhatsApp + Telegram)
```

**Files needed** (see `templates/` in this skill for ready-to-use examples):
- `render-health.py` — tiny Python HTTP server (stdlib only, zero deps)
- `Dockerfile` — extends `nousresearch/hermes-agent:latest`, adds the health server and a modified entrypoint
- `docker/entrypoint.sh` — launches both health server and gateway
- `render.yaml` — Render Blueprint config (optional, for declarative deploys)

**Setup steps:**
1. Create a GitHub repo with the files above
2. Render: **New Web Service** → point to your repo
3. Set env vars: `OPENROUTER_API_KEY`, `TELEGRAM_BOT_TOKEN`, `WHATSAPP_ENABLED=true`, `WHATSAPP_ALLOWED_USERS=<number>`, `WHATSAPP_MODE=self-chat`, `TELEGRAM_ALLOWED_USERS=<id>`, `TELEGRAM_WEBHOOK_URL=https://<your-app>.onrender.com`
4. No persistent disk needed (Free tier doesn't have one — auth is non-persistent)
5. Deploy
6. After deploy, pair WhatsApp via Render **Shell**: run `hermes whatsapp` → scan QR
7. ⚠️ On every deploy/restart, WhatsApp auth is lost. Must re-pair.

**Google Apps Script (keep-alive cron):**
```javascript
// https://script.google.com/ → New project
function pingHealth() {
  UrlFetchApp.fetch('https://YOUR-APP.onrender.com/');
}
// ⏰ Triggers: add trigger → time-driven → every 5 minutes
```

**Limitations of the Free approach:**
- WhatsApp pairing lost on every deploy (no persistent disk)
- Render may restart periodically for maintenance
- 750 compute-hours/month included; after that, pay-as-you-go at $0.09/hr
- Best for: testing, low-criticality bots, or users who accept occasional re-pairing

For production use without re-pairing, **Starter plan** ($7/mo, 1GB persistent disk + same keep-alive) is recommended.

### Step-by-step (Starter plan)

1. Create a **Web Service** → point to your GitHub fork of `NousResearch/hermes-agent` (or a private repo with the Dockerfile).
2. **Build**: Render auto-detects the Dockerfile.
3. **Start command**: `gateway run`
4. **Persistent Disk**: add in Render dashboard → mount at `/opt/data`
5. **Environment variables** — set these in Render dashboard:

Required:
```
HERMES_HOME=/opt/data
```

Optional but recommended:
```
HERMES_DASHBOARD=1                                      # Web UI on port 9119
HERMES_DASHBOARD_PORT=9119
HERMES_DASHBOARD_HOST=0.0.0.0
```

Platform env vars (example):
```
TELEGRAM_BOT_TOKEN=...
TELEGRAM_ALLOWED_USERS=...
TELEGRAM_WEBHOOK_URL=https://<your-app>.onrender.com

WHATSAPP_ENABLED=true
WHATSAPP_ALLOWED_USERS=554788952789
WHATSAPP_MODE=self-chat

OPENROUTER_API_KEY=...   # or ANTHROPIC_API_KEY, etc.
```

6. **First deploy** — Render builds, starts the container.
7. **WhatsApp**: after deploy, inject the pre-paired auth files into the persistent disk (Render Dashboard → Shell → copy/move files, or mount external tool).
8. **Health check**: Render health check path → `:9119/health` (or dashboard port). Set to avoid false crash detection.
9. **Deploy again**: on subsequent deploys, Render builds a new image but the persistent disk survives — config, auth, sessions intact.

### WhatsApp auth injection for Render

If you already paired locally:

```bash
# 1. Tar the auth from your local machine
tar czf whatsapp-auth.tar.gz -C ~/.hermes/gateway whatsapp-auth/

# 2. Upload to Render (use Render's Shell feature or SCP-like approach)
#    Render Dashboard → your service → Shell → then:
#    cd /opt/data/gateway && tar xzf /path/to/whatsapp-auth.tar.gz

# 3. Verify
ls /opt/data/gateway/whatsapp-auth/
# Should show: creds.json, session-*.json, pre-key-*.json, etc.
```

### Secret injection

Render has a "Secret Files" feature for `.env`. You can also inject individual env vars. Avoid putting secrets in build-time variables — set them as **Environment Variables** (live, not build-time).

## Railway (railway.app)

### Plan requirements

- **Free tier** works for low-volume use (limited credits per month).
- **Persistent disk**: add a Railway Volume attached to the service.
- **WebSocket**: Railway supports WebSocket natively.

### Step-by-step

1. Create **New Project** → **Deploy from GitHub** → select Hermes repo.
2. **Start command** (in Railway dashboard or `railway.json`): `gateway run`
3. **Volume**: add a volume mounted at `/opt/data` (at least 1GB).
4. **Environment**: same env vars as Render (see above), set via Railway dashboard.
5. **Health check**: Railway doesn't enforce health checks by default.
6. **Public networking**: Railway assigns a `.railway.app` domain automatically. Use that for `TELEGRAM_WEBHOOK_URL`.

### Pitfalls

- Railway free tier has **500 hours/month** and **$5 credit**. If the service runs 24/7, you burn through credits fast (~$5/mo minimum, ~$8-10 real). Consider a VPS for the same cost.
- Volume persists across deploys, but deleting the service destroys the volume.

## Fly.io (fly.io)

### Plan requirements

- **Free tier**: includes 3GB persistent volume, 1 shared CPU, 256MB RAM. Enough for Hermes at low volume.
- **WebSocket**: Fly supports long-lived WebSocket connections natively.
- **`fly.toml`**: needs `internal_port` pointing at the gateway's listen port.

### Step-by-step

1. Install Fly CLI (`flyctl`), login.
2. Clone the Hermes repo: `git clone https://github.com/NousResearch/hermes-agent`
3. Create a `fly.toml`:

```toml
app = "hermes-agent"
primary_region = "gru"  # São Paulo region if in Brazil
kill_signal = "SIGINT"
kill_timeout = "30"

[[services]]
  internal_port = 8443  # Can be any open port; the gateway listens here
  protocol = "tcp"

  [[services.ports]]
    port = 443
    handlers = ["tls", "http"]

  [[services.ports]]
    port = 80
    handlers = ["http"]

  [[services.ports]]
    port = 8443
    handlers = ["http"]
```

4. Create a persistent volume:

```bash
flyctl volumes create hermes_data --region gru --size 3
```

5. Deploy first time (will fail — just to create the app):

```bash
flyctl launch --no-deploy
```

6. Configure `fly.toml` mounts:

```toml
[[mounts]]
  source = "hermes_data"
  destination = "/opt/data"
```

7. Set secrets:

```bash
flyctl secrets set TELEGRAM_BOT_TOKEN=...
flyctl secrets set WHATSAPP_ENABLED=true
flyctl secrets set WHATSAPP_ALLOWED_USERS=554788952789
flyctl secrets set WHATSAPP_MODE=self-chat
flyctl secrets set OPENROUTER_API_KEY=...
# etc.
```

8. Deploy:

```bash
flyctl deploy
```

9. WhatsApp auth: use `flyctl ssh console` to copy auth files into `/opt/data/gateway/whatsapp-auth/`.

### Pitfalls

- Fly.io free credits deplete at ~$2-3/mo for this setup. You get $5 free on signup, then pay-as-you-go.
- Region choice matters for latency (gru = São Paulo, good for Brazil).
- App goes to "sleep" on free tier after inactivity? No — Fly doesn't sleep apps; it just charges for uptime.

## VPS (Hetzner, DigitalOcean, Oracle Cloud Free Tier)

### Why a VPS

- Cheapest at scale (~$4/mo Hetzner CX22). Full control.
- No WebSocket limitations — true persistent process.
- Systemd service for management.
- Works with any provider (OpenRouter, Anthropic, local models).

### Setup with systemd

1. Install Hermes on the VPS normally:

```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
```

2. Pair WhatsApp: `hermes whatsapp` (interactive SSH session).

3. Create systemd service:

```ini
# /etc/systemd/system/hermes-gateway.service
[Unit]
Description=Hermes Agent Gateway
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=%h/.local/bin/hermes gateway run
User=hermes
Group=hermes
Restart=always
RestartSec=10
Environment=HERMES_HOME=/opt/hermes-data
WorkingDirectory=/opt/hermes-data

[Install]
WantedBy=default.target
```

4. Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now hermes-gateway
sudo loginctl enable-linger $USER  # keeps process alive after SSH logout
```

5. No health checks needed — systemd's `Restart=always` handles crashes.

### Oracle Cloud Free Tier

Oracle Cloud offers an **always-free** ARM Ampere A1 instance (4 OCPUs, 24GB RAM, 200GB disk). This is the best free option for Hermes:

- Enough RAM to run local models (e.g. Llama 3.1 8B via llama.cpp)
- 4 ARM cores are performant
- 200GB boot volume is persistent
- Only downside: Oracle sometimes reclaims idle instances after 30 days if CPU usage is consistently <10%. Run some cron jobs to keep it active.

## Deployment Checklist

Use this when setting up on any platform:

- [ ] Dockerfile builds (or pull from Hermes repo)
- [ ] Persistent volume mounted at /opt/data
- [ ] GODMODE/WRITE permissions on the volume for the hermes user (UID 10000)
- [ ] `.env` or env vars set (at minimum: API key for model, and platform tokens)
- [ ] `config.yaml` present (first-boot auto-created or seeded)
- [ ] WhatsApp pre-paired (auth files in `/opt/data/gateway/whatsapp-auth/`)
- [ ] Telegram in webhook mode (with `TELEGRAM_WEBHOOK_URL`)
- [ ] Health check configured (if the platform requires one)
- [ ] First manual test: send a message from each platform, verify it reaches Hermes
- [ ] Logs accessible (Render: Dashboard logs; Fly: `flyctl logs`; VPS: `journalctl`)

## Cost Comparison (2025)

| Platform | Min plan | Persistent storage | WebSocket | Monthly cost | WhatsApp works? |
|----------|----------|-------------------|-----------|-------------|-----------------|
| Render | Starter | 1GB | ✅ | ~$7 | ✅ With disk |
| Render Free | None | ❌ | ✅ (with keep-alive) | $0 | ⚠️ Re-pair after each deploy |
| Railway | Free tier | via Volume | ✅ | ~$5-8 with usage | ✅ With volume |
| Fly.io | Free credits | 3GB | ✅ | ~$3-5 with usage | ✅ With volume |
| Hetzner CX22 | VPS | 40GB SSD | ✅ | ~$4 | ✅ Full control |
| Oracle Cloud | Free | Up to 200GB | ✅ | $0 | ✅ (needs manual setup) |
