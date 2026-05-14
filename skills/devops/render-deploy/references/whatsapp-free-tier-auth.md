# WhatsApp Auth Injection — Render Free Tier

## Problem

Render Free tier offers no Shell access and no persistent disk. WhatsApp (Baileys) requires
a multi-file auth state at `$HERMES_HOME/whatsapp/session/` (~4,094 files, ~17MB). Without
Shell, you can't run `hermes whatsapp` inside the container. Without a disk, auth is lost on
every restart.

## Solution

Embed a pre-paired session tarball in the Docker image so it's always available on startup.

## Key Architecture

| Component | Location | Purpose |
|-----------|----------|---------|
| `auth/session.tar.gz` | In repo (git-tracked) | Gzipped tarball of critical auth files |
| `auth/restore-session.sh` | Copied to `/opt/hermes/auth/` | Extracts tarball if creds.json missing |
| `auth/update-session.sh` | Local dev tool | Regenerates tarball from current local session |
| Entrypoint call | `docker/entrypoint.sh` root block | Calls restore-session.sh before gosu drop |

## Critical auth files

The tarball includes only what Baileys cannot regenerate from the server:

- `creds.json` — client ID, server token, registration ID (~3KB)
- `pre-key-*.json` — pre-keys for E2EE
- `identity-key-*.json` — identity key pairs
- `sender-key-*.json` — sender key records (group E2EE)
- `app-state-*.json` — app state sync data

Session-*.json files (chat history caches) are excluded — they get re-synced from server.

## Session lifecycle

1. Pair locally → `~/.hermes/whatsapp/session/` populated with ~4K files
2. `bash auth/update-session.sh` → creates `auth/session.tar.gz` (~116KB)
3. Commit + push → Render builds Docker image with tarball embedded
4. Container starts → entrypoint (root) extracts tarball → gosu drop → hermes user starts bridge
5. Bridge loads creds → connects without QR code
6. Session expires after 1-4 weeks → repeat from step 1

## Files in project

### restore-session.sh
```bash
#!/bin/bash
SESSION_DIR="${HERMES_HOME:-/opt/data}/whatsapp/session"
AUTH_FILE="/opt/hermes/auth/session.tar.gz"
if [ -f "$AUTH_FILE" ] && [ ! -f "$SESSION_DIR/creds.json" ]; then
    mkdir -p "$SESSION_DIR"
    tar xzf "$AUTH_FILE" -C "$SESSION_DIR"
fi
```

### update-session.sh
```bash
#!/bin/bash
SESSION_SRC="${HERMES_HOME:-$HOME/.hermes}/whatsapp"
cd "$SESSION_SRC"
tar czf "$(dirname "$0")/session.tar.gz" \
    session/creds.json session/pre-key-*.json \
    session/identity-key-*.json session/sender-key-*.json \
    session/app-state-*.json
```

## Pitfalls

- **npm install timeout (60s) no runtime:** O gateway roda `npm install --silent` na pasta
  `whatsapp-bridge` toda vez que inicia. A dependência `@whiskeysockets/baileys` (via git)
  pode estourar o timeout padrão de 60s. **Solução:** pré-instalar no Dockerfile:
  ```dockerfile
  RUN BRIDGE_DIR=$(/opt/hermes/.venv/bin/python3 -c "from pathlib import Path; import hermes_agent; print(Path(hermes_agent.__file__).parent / 'scripts' / 'whatsapp-bridge')") && \
      echo "WhatsApp bridge dir: $BRIDGE_DIR" && \
      cd "$BRIDGE_DIR" && \
      npm install --timeout=300000
  ```
- **bridge.log Permission denied (Errno 13):** O gateway abre `/opt/data/whatsapp/bridge.log`
  como usuário `hermes`. Se o diretório `whatsapp/` não existir ou estiver com dono errado
  (ex: de execução anterior com Persistent Disk), o gateway falha. **Solução no entrypoint:**
  1. Adicionar `whatsapp` no `mkdir -p "$HERMES_HOME"/{...,whatsapp}`
  2. Fazer `chown -R` **sempre** (não condicional) no bloco root antes do `gosu`
- **CRLF line endings quebram .sh no container:** Shell scripts editados no Windows (CRLF)
  falham com `\r: command not found` dentro do container Linux. Converter antes do commit:
  ```bash
  sed -i 's/\r$//' docker/entrypoint.sh auth/restore-session.sh auth/update-session.sh
  ```
- **Tarball too large for Render Secret Files:** At ~116KB gzipped (~156KB base64), it exceeds
  Render's 100KB Secret File limit. Must be committed to repo and embedded in Docker image.
- **Git push fails from WSL:** No credential helper configured. Workaround: use GitHub web UI
  drag-and-drop to upload `auth/session.tar.gz` file.
- **Session expires silently:** The bridge reconnects until WhatsApp invalidates the creds.
  When it stops working, run `hermes whatsapp` locally, update tarball, commit, push.
