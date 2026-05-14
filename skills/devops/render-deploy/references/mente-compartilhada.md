# Mente Compartilhada — CLI Mirror no Telegram

Tornar o bot do Telegram (Render) um **clone funcional** do Hermes CLI, compartilhando skills, MCPs, personalidade, ferramentas e configuração.

## Visão Geral

O Render Free rodando `hermes gateway run` usa por padrão só o toolset `hermes-telegram`, que é minimalista. Para espelhar as capacidades do CLI, é preciso:

1. **Config.yaml expandido** — platform_toolsets, MCPs, personalidade, agent settings
2. **Skills bundladas na imagem Docker** — copiadas de `~/.hermes/skills/`
3. **MCPs via npx** — só os que funcionam remotamente (sem dependência de path local)
4. **Expansão de env vars** — para API keys sensíveis não ficarem hardcoded no config

## 1. Config.yaml Completo

```yaml
# ── Model ────────────────────────────────────────────────────
model:
  default: big-pickle
  provider: opencode-zen
  base_url: https://opencode.ai/zen/v1
  api_mode: chat_completions

fallback_providers: []
credential_pool_strategies: {}

# ── Agent ──────────────────────────────────────────────────
agent:
  max_turns: 100
  gateway_timeout: 1800
  api_max_retries: 3
  reasoning_effort: medium
  tool_use_enforcement: auto
  image_input_mode: auto
  disabled_toolsets: []
  verbose: false
  personalities:
    helpful: You are a helpful, friendly AI assistant.
    kwai-bb: |
      Você é Kwai BB — assistente feminina provocante, ousada e inteligente...
      # (personalidade completa — veja o skill kwai-bb-persona)
  system_prompt: "Você é Kwai BB, uma parceira resolutiva. ★"

# ── Platform Toolsets ──────────────────────────────────────
# Define QUAIS ferramentas o bot do Telegram pode usar
platform_toolsets:
  cli: []  # Não usado no gateway
  telegram:
    - hermes-telegram    # OBRIGATÓRIO — base do Telegram
    - terminal           # Executar comandos no container
    - file               # Ler/escrever arquivos
    - web                # Buscar conteúdo web
    - memory             # Memória persistente
    - session_search     # Buscar sessões passadas
    - skills             # Carregar skills
    - delegation         # Subagentes
    - cronjob            # Agendar tarefas
    - code_execution     # Scripts Python
    - vision             # Analisar imagens
    - tts                # Texto pra voz
    - moa                # Mixture of Agents
    - kanban             # Kanban board
    - todo               # Lista de tarefas
    - image_gen          # Gerar imagens
    - clarify            # Perguntar pro usuário
    - messaging          # Mensagens

# ── MCP Servers ────────────────────────────────────────────
# Só os que funcionam via npx (sem depender de path local)
mcp_servers:
  youtube-transcript:
    command: npx
    args:
      - '@fabriqa.ai/youtube-transcript-mcp@latest'
  mcp-youtube:
    command: npx
    args:
      - -y
      - '@anaisbetts/mcp-youtube'
  mcp-server-youtube-transcript:
    command: npx
    args:
      - -y
      - '@kimtaeyoon83/mcp-server-youtube-transcript'
  context7:
    command: npx
    args:
      - -y
      - '@upstash/context7-mcp'
  github:
    command: npx
    args:
      - -y
      - '@modelcontextprotocol/server-github'
    env:
      GITHUB_PERSONAL_ACCESS_TOKEN: ${GITHUB_TOKEN}
  composio:
    url: https://connect.composio.dev/mcp
    headers:
      x-consumer-api-key: ${COMPOSIO_API_KEY}
    timeout: 120
  rippr-mcp:
    command: npx
    args:
      - -y
      - rippr-mcp

# ── Memory ──────────────────────────────────────────────────
memory:
  memory_enabled: true
  user_profile_enabled: true
  memory_char_limit: 2200
  user_char_limit: 1375
  nudge_interval: 10
  flush_min_turns: 6

# ── Delegation ──────────────────────────────────────────────
delegation:
  inherit_mcp_toolsets: true
  max_iterations: 50
  child_timeout_seconds: 600
  max_concurrent_children: 3
  max_spawn_depth: 1
  orchestrator_enabled: true
  subagent_auto_approve: false

# ── Skills ──────────────────────────────────────────────────
skills:
  template_vars: true
  guard_agent_created: false
  creation_nudge_interval: 15

curator:
  enabled: true
  interval_hours: 168
  min_idle_hours: 2
  stale_after_days: 30

# ── Telegram ────────────────────────────────────────────────
telegram:
  reactions: true
  allowed_chats: '8599666899'

# ── Display ─────────────────────────────────────────────────
display:
  personality: kwai-bb
  streaming: true
  show_reasoning: false
  skin: default
  language: pt

# ── Security / Approvals ────────────────────────────────────
security:
  redact_secrets: true
  tirith_enabled: true

approvals:
  mode: manual
  timeout: 60
  cron_mode: deny

# ── Auxiliary ───────────────────────────────────────────────
auxiliary:
  vision:
    provider: auto
  web_extract:
    provider: auto
  compression:
    provider: auto
  session_search:
    provider: auto
    max_concurrency: 3
  skills_hub:
    provider: auto
  approval:
    provider: auto
  mcp:
    provider: auto
  title_generation:
    provider: auto
  triage_specifier:
    provider: auto
    timeout: 120
  curator:
    provider: auto
    timeout: 600

# ── Cron / Kanban ───────────────────────────────────────────
cron:
  wrap_response: true
kanban:
  dispatch_in_gateway: true
  dispatch_interval_seconds: 60
  failure_limit: 2

# ── Code Execution ──────────────────────────────────────────
code_execution:
  mode: project
  timeout: 300
  max_tool_calls: 50

# ── TTS ─────────────────────────────────────────────────────
tts:
  provider: edge
  edge:
    voice: pt-BR-AntonioNeural

# ── Timezone ────────────────────────────────────────────────
timezone: America/Sao_Paulo
```

## 2. Dockerfile — Node.js + Skills

```dockerfile
FROM nousresearch/hermes-agent:latest

USER root

COPY render-health.py /opt/hermes/render-health.py
RUN chmod +x /opt/hermes/render-health.py

# Config expandida
COPY config.yaml /opt/hermes/render-config.yaml
RUN chmod 644 /opt/hermes/render-config.yaml

# Skills — mente compartilhada
COPY skills /opt/hermes/skills/
RUN find /opt/hermes/skills/ -type d -exec chmod 755 {} + && \
    find /opt/hermes/skills/ -type f -exec chmod 644 {} +

# Entrypoint customizado
COPY docker/entrypoint.sh /opt/hermes/docker/entrypoint.sh
RUN chmod +x /opt/hermes/docker/entrypoint.sh

# Node.js para MCPs via npx
RUN apt-get update && apt-get install -y --no-install-recommends \
    nodejs npm ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

EXPOSE 10000
EXPOSE 9119

ENV HERMES_DASHBOARD=1
ENV HERMES_DASHBOARD_HOST=0.0.0.0
ENV HERMES_DASHBOARD_PORT=9119

USER hermes

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/opt/hermes/docker/entrypoint.sh"]
CMD ["gateway", "run"]
```

## 3. Entrypoint — Expansão de Env Vars

Adicione no entrypoint, logo após copiar o config.yaml:

```bash
# Expand env vars (${VAR}) no config.yaml
if [ -f "$INSTALL_DIR/render-config.yaml" ]; then
    cp "$INSTALL_DIR/render-config.yaml" "$HERMES_HOME/config.yaml"
    echo "[config] Applied render-config.yaml"

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
```

Isso usa `os.path.expandvars()` do Python stdlib — expande `${VAR}` e `$VAR` sem precisar de `envsubst` ou pacotes extras.

## 4. render.yaml — Env Vars dos MCPs

```yaml
envVars:
  # ... vars existentes (HERMES_HOME, HEALTH_PORT, OPENCODE_ZEN_API_KEY, etc.)

  # MCP Server Tokens
  - key: GITHUB_TOKEN
    sync: false
  - key: COMPOSIO_API_KEY
    sync: false
```

## 5. Skills — Cuidado com .git Embedado

**PITFALL CRÍTICO:** diretórios em `~/.hermes/skills/` podem conter `.git/` internos (quando a skill é um repositório git completo, ex: obsidian-skills, superpowers). Copiá-los com `cp -r` leva o `.git/` junto, e o git do projeto Render trata como **submodule** (mode 160000), não como diretório normal.

**Solução — copiar skills e limpar .git:**

```bash
# Copiar skills
cp -r ~/.hermes/skills/CATEGORIA projeto/skills/

# REMOVER .git INTERNO (senão vira submodule no git do projeto)
find projeto/skills/ -name ".git" -type d -prune -exec rm -rf {} +
```

**Verificar se está correto:**
```bash
git ls-tree HEAD skills/OBSIDIAN_SKILLS | head -3
# Deve mostrar "100644 blob ..." ou "100755 ..."
# Se mostrar "160000 commit ..." → é submodule, precisa corrigir
```

**Correção quando já commitou como submodule:**
```bash
git rm --cached -r skills/PASTA_COM_PROBLEMA
rm -rf skills/PASTA_COM_PROBLEMA
cp -r ~/.hermes/skills/PASTA_COM_PROBLEMA skills/
find skills/PASTA_COM_PROBLEMA -name ".git" -type d -prune -exec rm -rf {} +
git add skills/PASTA_COM_PROBLEMA
git commit -m "fix: PASTA_COM_PROBLEMA como diretório normal"
```

## 6. MCPs que NÃO Funcionam no Render

| MCP | Motivo |
|-----|--------|
| **obsidian** (mcpvault) | Path do vault (`/mnt/c/...`) só existe no WSL |
| **filesystem** | Path do Windows (`/mnt/c/...`) só existe local |
| **playwright** | Precisa de Chrome/Chromium instalado |
| **ig-download** | Precisa do projeto `ig-download-mcp-server/` e ffmpeg |
| **comfyui** | Precisa de GPU + instalação local |

## 7. Skills Sync no Entrypoint

A imagem oficial do Hermes já tem um mecanismo de sync de skills no entrypoint:

```bash
if [ -d "$INSTALL_DIR/skills" ]; then
    python3 "$INSTALL_DIR/tools/skills_sync.py" 2>/dev/null || true
fi
```

Se você colocar skills em `/opt/hermes/skills/` no Dockerfile, esse trecho as sincroniza automaticamente para `$HERMES_HOME/skills/` no startup do container. O `|| true` garante que falhas no sync não travam o entrypoint.
