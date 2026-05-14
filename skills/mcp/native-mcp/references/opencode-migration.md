# Migrating MCPs from OpenCode to Hermes

## OpenCode MCP Configuration

OpenCode stores MCP server configs in `opencode.json` under the `mcp` key:

```json
{
  "mcp": {
    "server-name": {
      "type": "local",
      "command": ["npx", "package-name@version", "arg1"],
      "enabled": true,
      "env": {
        "API_KEY": "value"
      }
    }
  }
}
```

## Hermes MCP Configuration

Hermes stores MCP server configs in `~/.hermes/config.yaml` under the `mcp_servers` key:

```yaml
mcp_servers:
  server-name:
    command: "npx"
    args: ["package-name@version", "arg1"]
    env:
      API_KEY: "value"
    timeout: 120
    connect_timeout: 60
```

## Migration Steps

1. **Read `opencode.json`** — Located at `/mnt/c/Users/<user>/.config/opencode/opencode.json` (WSL) or `%USERPROFILE%\.config\opencode\opencode.json` (Windows).

2. **Convert each MCP server**:
   - `type: "local"` with `command` array → Hermes `command` (first element) and `args` (remaining elements)
   - `enabled: false` → omit from Hermes config
   - `env` → same structure, just convert JSON to YAML

3. **Handle Windows paths in WSL** — Convert `C:/Users/...` to `/mnt/c/Users/...`.

4. **Install `mcp` Python package** — Hermes requires `pip install mcp` for MCP support.

5. **Restart Hermes** — MCP servers are discovered at startup.

## Example: Obsidian MCP

OpenCode config:
```json
"obsidian": {
  "type": "local",
  "command": ["npx", "@bitbonsai/mcpvault@latest", "C:/Users/keila/Mateus/vault"],
  "enabled": true
}
```

Hermes config:
```yaml
mcp_servers:
  obsidian:
    command: "npx"
    args: ["@bitbonsai/mcpvault@latest", "/mnt/c/Users/keila/Mateus/vault"]
```

## Common OpenCode MCPs

| Server | Package | Purpose |
|--------|---------|---------|
| obsidian | `@bitbonsai/mcpvault` | Obsidian vault access |
| youtube-transcript | `@fabriqa.ai/youtube-transcript-mcp` | YouTube transcripts |
| playwright | `@playwright/mcp` | Browser automation |
| context7 | `@upstash/context7-mcp` | Library documentation |
| github | `@modelcontextprotocol/server-github` | GitHub API |
| filesystem | `@modelcontextprotocol/server-filesystem` | File system access |
