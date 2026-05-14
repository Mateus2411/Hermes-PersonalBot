# Canva MCP Server Integration

## Overview

There are two MCP servers related to Canva:

1. **Canva Dev MCP Server** (official) — helps developers build Canva apps/integrations. Configured via canva.dev MCP endpoint.
2. **Canva API MCP Server** (community, `mattcoatsworth/canva-mcp-server`) — wraps the Canva Connect REST API for managing designs, brands, assets, and users.

This reference covers **option 2** — the community server that lets the agent interact with Canva designs programmatically.

## Repository

- **GitHub**: https://github.com/mattcoatsworth/canva-mcp-server
- **Stars**: 6 | **Forks**: 4 | **Last updated**: ~last year
- **Node.js based** (uses @modelcontextprotocol/sdk + express + axios)

## Features

The server provides these MCP tools:

| Tool | Description |
|------|-------------|
| `get_design` | Get info about a specific design |
| `list_designs` | List designs with pagination |
| `get_brand` | Get info about a specific brand |
| `list_brands` | List brands with pagination |
| `get_asset` | Get info about a specific asset |
| `list_assets` | List assets (filterable by type) |
| `upload_image` | Upload an image to Canva from a URL |
| `get_user` | Get info about a specific user |
| `list_users` | List users with pagination |

## Prerequisites

- **Node.js v20+** and **npm**
- **Canva Developer account** at https://www.canva.com/developers
- **Canva API credentials**: `CANVA_APP_ID` + `CANVA_API_KEY`

## Setup Steps

### 1. Get Canva API Credentials

1. Go to https://www.canva.com/developers
2. Create an app / integration
3. Get your **App ID** and **API Key**

### 2. Clone and Install

```bash
git clone https://github.com/mattcoatsworth/canva-mcp-server.git
cd canva-mcp-server
npm install
```

### 3. Configure Environment

```bash
cp .env.example .env
```

Edit `.env`:
```
CANVA_API_KEY=your_api_key_here
```

The server also reads `CANVA_APP_ID` from the environment.

### 4. Configure in Hermes

Add to `~/.hermes/config.yaml` under `mcp_servers`:

```yaml
mcp_servers:
  canva:
    command: "node"
    args: ["/absolute/path/to/canva-mcp-server/src/index.js"]
    timeout: 120
    env:
      CANVA_API_KEY: "your_api_key_here"
```

Or using the cloned directory:
```yaml
mcp_servers:
  canva:
    command: "npm"
    args: ["start", "--prefix", "/path/to/canva-mcp-server"]
    timeout: 120
    env:
      CANVA_API_KEY: "your_api_key_here"
```

### 5. Restart Hermes

After restart, tools will be available as `mcp_canva_*`:
- `mcp_canva_get_design`
- `mcp_canva_list_designs`
- `mcp_canva_get_brand`
- `mcp_canva_list_brands`
- `mcp_canva_get_asset`
- `mcp_canva_list_assets`
- `mcp_canva_upload_image`
- `mcp_canva_get_user`
- `mcp_canva_list_users`

## Mock Data Mode

If `CANVA_APP_ID` or `CANVA_API_KEY` are missing, the server auto-switches to **mock data mode** — all tools return fake/sample data. This is useful for testing the integration without real credentials.

The mock mode logs a warning: `"Warning: Canva API credentials not found in environment variables. Using mock data."`

## Canva Connect API Reference

The server wraps the official Canva Connect API v1 (`https://api.canva.com/v1`):

- **Authentication**: Bearer token (`Authorization: Bearer ${API_KEY}`) + `X-Canva-App-Id` header
- **Official docs**: https://www.canva.dev/docs/connect/
- **OpenAPI spec**: Available at https://www.canva.dev/docs/connect/

### API Endpoints Covered

| Endpoint | Method | Tool |
|----------|--------|------|
| `/designs/{id}` | GET | `get_design` |
| `/designs` | GET | `list_designs` |
| `/brands/{id}` | GET | `get_brand` |
| `/brands` | GET | `list_brands` |
| `/assets/{id}` | GET | `get_asset` |
| `/assets` | GET | `list_assets` |
| `/assets/images` | POST | `upload_image` |
| `/users/{id}` | GET | `get_user` |
| `/users` | GET | `list_users` |

## See Also

For a more complete Canva integration with 32 tools (including design creation, export, autofill, folder management, and comments via OAuth2), see **`references/composio-canva.md`** — Composio wraps the same Canva Connect API but with managed authentication and write operations.

## Limitations

- **No design creation/editing tools** — only read operations + upload_image. The server doesn't wrap Canva's design create/autofill endpoints.
- **Community maintained** — only 6 stars, 9 commits, last updated ~1 year ago
- **No SSE/HTTP MCP endpoint** — runs only as stdio subprocess
