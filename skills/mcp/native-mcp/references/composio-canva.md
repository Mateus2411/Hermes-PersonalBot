# Canva via Composio (MCP Integration)

## Overview

[Composio](https://composio.dev) offers a Canva integration with **32 tools** via OAuth2 — much more complete than the community `mattcoatsworth/canva-mcp-server` (which only has 9 read-only tools + upload_image).

Key advantage: Composio manages OAuth2 authentication (token creation, refresh, scopes) so you don't have to. Just authenticate once and the tools work.

## Tools Available (32 total)

| Tool | Description |
|------|-------------|
| `create_design` | Create a new Canva design with preset or custom dimensions + optional asset |
| `list_brand_templates` | List brand templates for the user |
| `export_design` | Initiate design export job (PDF, PNG, JPG, etc.) |
| `get_export_job_result` | Get download links for exported design pages |
| `autofill_design` | Initiate design autofill job (fill brand template with data) |
| `get_autofill_job_status` | Check design autofill job status |
| `list_designs` | List user designs with search filtering and sorting |
| `get_design_metadata` | Get metadata and access info for a design |
| `list_design_pages` | List design pages with pagination |
| `upload_asset` | Create asset upload job |
| `get_upload_job_status` | Fetch asset upload job status |
| `delete_asset` | Delete asset by ID |
| `get_asset_metadata` | Retrieve asset metadata |
| `create_folder` | Create user or sub-folder in projects |
| `get_folder_details` | Retrieve folder details by ID |
| `list_folder_items` | List folder items by type with sorting |
| `move_item` | Move item to specified folder |
| `delete_folder` | Remove folder (move contents to trash) |
| `create_comment` | Create design comment (preview API) |
| `reply_to_comment` | Create comment reply in design (preview API) |
| `get_comment` | Retrieve a specific design comment (preview API) |
| `get_current_user` | Fetch current user details (id, team_id, display_name) |
| `get_user_profile` | Retrieve user profile data |
| `import_design` | Initiate design import job |
| `get_import_job_status` | Retrieve design import job status |
| `get_brand_template_metadata` | Retrieve Canva enterprise brand template metadata |
| `get_brand_template_dataset` | Retrieve brand template dataset definition |
| `get_app_public_keys` | Retrieve app public key set |
| `get_connect_signing_keys` | Fetch Canva Connect signing public keys |
| `exchange_token` | Exchange OAuth 2.0 access or refresh token |
| `list_design_comments` | (preview API) |

## Setup in Hermes Agent

### 1. Create Composio account

Sign up at https://composio.dev and get your API key.

### 2. Install and auth the Canva integration

```bash
# Install Composio CLI
curl -fsSL https://composio.dev/install | bash

# Add the Canva integration
composio add canva
# This will open OAuth2 flow — authenticate with your Canva account
```

### 3. Get MCP connection string

```bash
composio mcp get
# Returns a connection string or config snippet
```

### 4. Configure in Hermes

Add to `~/.hermes/config.yaml`:

```yaml
mcp_servers:
  composio:
    command: "npx"
    args: ["-y", "@composio/mcp"]
    env:
      COMPOSIO_API_KEY: "sua_chave_aqui"
    timeout: 120
```

### 5. Restart Hermes

After restart, tools appear as `mcp_composio_*` — e.g. `mcp_composio_create_design`, `mcp_composio_list_designs`, etc.

## Comparison: Composio vs. Community MCP Server

| Aspect | Composio | mattcoatsworth/canva-mcp-server |
|--------|----------|----------------------------------|
| Tools | 32 (read + write) | 9 (mostly read) |
| Auth | OAuth2 (managed) | API Key (Bearer token) |
| Create designs | Yes | No |
| Export designs | Yes (PDF, PNG, JPG) | No |
| Autofill templates | Yes | No |
| Comments | Yes (preview) | No |
| Folder management | Yes (CRUD) | No |
| Maintenance | Active (part of Composio platform) | Low activity (~1yr old, 6 stars) |
| Mock mode | No | Yes (when no credentials) |
| Pricing | Free tier + paid plans | Free (open source) |

## Limitations

- Requires internet and a Composio account
- OAuth2 token must be refreshed periodically (Composio handles this)
- Some comment/design-page APIs are marked as "preview" by Canva
- Brand template IDs will change (Canva announced migration window)
- Pricing may apply beyond free tier

## References

- Composio Canva toolkit: https://composio.dev/toolkits (search "Canva")
- Composio MCP docs: https://docs.composio.dev
- Canva Connect API docs: https://www.canva.dev/docs/connect/
