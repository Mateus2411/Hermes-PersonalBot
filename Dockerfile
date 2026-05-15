# Render-optimized Hermes Agent — 24/7 online with health endpoint
#
# Builds on top of the official Hermes Agent image, adding:
#   - render-health.py  (simple HTTP server returning "ok" + uptime)
#   - entrypoint.sh     (runs health server + gateway together)
#
# Why this works on Render Free tier:
#   Render spins down after 15 min of inactivity.  Our health endpoint
#   gets pinged every 5 min by Google Apps Script → Render stays awake
#   → Telegram stays connected 24/7.
#
# Build from repo root:
#   docker build -t hermes-render .
#
# Run locally to test:
#   docker run -p 10000:10000 -p 9119:9119 \
#     -e TELEGRAM_BOT_TOKEN=... \
#     -e OPENCODE_ZEN_API_KEY=... \
#     hermes-render

FROM nousresearch/hermes-agent:latest

USER root

# ─── Telegram dependency ──────────────────────────────────────────────
# python-telegram-bot é necessário para o gateway do Telegram funcionar.
# Instala com pip do sistema (disponível globalmente na imagem oficial)
RUN pip install python-telegram-bot

# Copy the health server
COPY render-health.py /opt/hermes/render-health.py
RUN chmod +x /opt/hermes/render-health.py

# Custom config.yaml — Render-optimized (opencode-zen + kwai-bb + toolsets + MCPs)
COPY config.yaml /opt/hermes/render-config.yaml
RUN chmod 644 /opt/hermes/render-config.yaml

# Skills — mente compartilhada com o CLI
COPY skills /opt/hermes/skills/
RUN find /opt/hermes/skills/ -type d -exec chmod 755 {} + && \
    find /opt/hermes/skills/ -type f -exec chmod 644 {} +

# Replace the entrypoint with our multi-process version
COPY docker/entrypoint.sh /opt/hermes/docker/entrypoint.sh
RUN chmod +x /opt/hermes/docker/entrypoint.sh

# Health server port
EXPOSE 10000
# Hermes dashboard
EXPOSE 9119

# Default: start gateway.  Override via Render start command.
ENV HERMES_DASHBOARD=1
ENV HERMES_DASHBOARD_HOST=0.0.0.0
ENV HERMES_DASHBOARD_PORT=9119

USER hermes

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/opt/hermes/docker/entrypoint.sh"]
CMD ["gateway", "run"]
