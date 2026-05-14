#!/bin/bash
# Docker entrypoint for Render — runs health server + Hermes gateway.
set -e

HERMES_HOME="${HERMES_HOME:-/opt/data}"
INSTALL_DIR="/opt/hermes"

# --- Privilege dropping via gosu ---
if [ "$(id -u)" = "0" ]; then
    if [ -n "$HERMES_UID" ] && [ "$HERMES_UID" != "$(id -u hermes)" ]; then
        echo "Changing hermes UID to $HERMES_UID"
        usermod -u "$HERMES_UID" hermes
    fi
    if [ -n "$HERMES_GID" ] && [ "$HERMES_GID" != "$(id -g hermes)" ]; then
        echo "Changing hermes GID to $HERMES_GID"
        groupmod -o -g "$HERMES_GID" hermes 2>/dev/null || true
    fi
    actual_hermes_uid=$(id -u hermes)
    needs_chown=false
    if [ -n "$HERMES_UID" ] && [ "$HERMES_UID" != "10000" ]; then
        needs_chown=true
    elif [ "$(stat -c %u "$HERMES_HOME" 2>/dev/null)" != "$actual_hermes_uid" ]; then
        needs_chown=true
    fi
    if [ "$needs_chown" = true ]; then
        echo "Fixing ownership of $HERMES_HOME to hermes ($actual_hermes_uid)"
        chown -R hermes:hermes "$HERMES_HOME" 2>/dev/null || \
            echo "Warning: chown failed (rootless container?) — continuing anyway"
    fi
    if [ -f "$HERMES_HOME/config.yaml" ]; then
        chown hermes:hermes "$HERMES_HOME/config.yaml" 2>/dev/null || true
        chmod 640 "$HERMES_HOME/config.yaml" 2>/dev/null || true
    fi
    echo "Dropping root privileges"
    exec gosu hermes "$0" "$@"
fi

# --- Running as hermes from here ---
source "${INSTALL_DIR}/.venv/bin/activate"

# Create essential directories
mkdir -p "$HERMES_HOME"/{cron,sessions,logs,hooks,memories,skills,skins,plans,workspace,home}

# Bootstrap config files
if [ ! -f "$HERMES_HOME/.env" ]; then
    cp "$INSTALL_DIR/.env.example" "$HERMES_HOME/.env"
fi

# Always deploy our Render-optimized config.yaml (provider = opencode-zen only)
if [ -f "$INSTALL_DIR/render-config.yaml" ]; then
    cp "$INSTALL_DIR/render-config.yaml" "$HERMES_HOME/config.yaml"
    echo "[config] Applied render-config.yaml (opencode-zen only, no router)"

    # Expand env vars (${VAR}) in the config — suporta GITHUB_TOKEN, COMPOSIO_API_KEY etc.
    python3 -c "
import os
path = '$HERMES_HOME/config.yaml'
with open(path) as f:
    content = f.read()
content = os.path.expandvars(content)
with open(path, 'w') as f:
    f.write(content)
" 2>/dev/null || true
    echo "[config] Environment variables expanded"
fi
# ─── Clean up MCP servers — remove tudo que precisa de Node.js/npx ────
# No Render Free (512MB RAM) não tem Node.js instalado. Só mantemos
# servidores URL-based (composio). Tudo que usa npx é removido.
python3 -c "
import yaml, os
path = '$HERMES_HOME/config.yaml'
with open(path) as f:
    cfg = yaml.safe_load(f)
mcp = cfg.get('mcp_servers', {})
if not mcp:
    exit(0)

changed = False
servers_to_remove = []

for name, svc in mcp.items():
    if not isinstance(svc, dict):
        servers_to_remove.append(name)
        changed = True
        continue

    cmd = svc.get('command', '')

    # Remove servidores que usam npx/node — não temos Node.js no container
    if cmd in ('npx', 'node'):
        print(f'[mcp] Removing \"{name}\" — needs {cmd} (not installed)')
        servers_to_remove.append(name)
        changed = True
        continue

    # Remove servidores com paths locais (obsidian, filesystem, ig-download)
    args = svc.get('args', [])
    args_str = ' '.join(str(a) for a in args)
    if any(p in args_str for p in ['/mnt/', '/home/', '/Users/']):
        print(f'[mcp] Removing \"{name}\" — local path: {args_str[:60]}')
        servers_to_remove.append(name)
        changed = True
        continue

    # Composio: update API key from env var
    url = svc.get('url', '')
    if 'composio' in url and 'x-consumer-api-key' in svc.get('headers', {}):
        ck = os.environ.get('COMPOSIO_API_KEY', '')
        if ck:
            svc['headers']['x-consumer-api-key'] = ck
            print('[mcp] Updated composio API key from env')
            changed = True

for name in servers_to_remove:
    del mcp[name]

if changed:
    cfg['mcp_servers'] = mcp or {}
    with open(path, 'w') as f:
        yaml.dump(cfg, f, default_flow_style=False)
    print('[mcp] MCP config cleaned up')
" 2>/dev/null || true

if [ ! -f "$HERMES_HOME/SOUL.md" ]; then
    cp "$INSTALL_DIR/docker/SOUL.md" "$HERMES_HOME/SOUL.md"
fi
if [ ! -f "$HERMES_HOME/auth.json" ] && [ -n "$HERMES_AUTH_JSON_BOOTSTRAP" ]; then
    printf '%s' "$HERMES_AUTH_JSON_BOOTSTRAP" > "$HERMES_HOME/auth.json"
    chmod 600 "$HERMES_HOME/auth.json"
fi

# Sync bundled skills
if [ -d "$INSTALL_DIR/skills" ]; then
    python3 "$INSTALL_DIR/tools/skills_sync.py" 2>/dev/null || true
fi

# ─── Render-specific: start health server ──────────────────────────
HEALTH_PORT="${HEALTH_PORT:-10000}"
echo "[health] Starting render-health.py on :${HEALTH_PORT}"
python3 /opt/hermes/render-health.py &
# Give it a moment to bind
sleep 1

# ─── Optional: Hermes dashboard ────────────────────────────────────
case "${HERMES_DASHBOARD:-}" in
    1|true|TRUE|True|yes|YES|Yes)
        dash_host="${HERMES_DASHBOARD_HOST:-0.0.0.0}"
        dash_port="${HERMES_DASHBOARD_PORT:-9119}"
        dash_args=(--host "$dash_host" --port "$dash_port" --no-open)
        if [ "$dash_host" != "127.0.0.1" ] && [ "$dash_host" != "localhost" ]; then
            dash_args+=(--insecure)
        fi
        echo "[dashboard] Starting Hermes dashboard on ${dash_host}:${dash_port}"
        (
            stdbuf -oL -eL hermes dashboard "${dash_args[@]}" 2>&1 \
                | sed -u 's/^/[dashboard] /'
        ) &
        ;;
esac

# ─── Final exec ────────────────────────────────────────────────────
if [ $# -gt 0 ] && command -v "$1" >/dev/null 2>&1; then
    exec "$@"
fi
exec hermes "$@"
