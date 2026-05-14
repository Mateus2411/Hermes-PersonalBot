---
name: web-api-discovery
description: Methodology for discovering and documenting web API endpoints from frontend JavaScript applications — identifying API subdomains, enumerating routes via debug pages, and extracting OpenAPI/Swagger schemas.
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [api, recon, reverse-engineering, spa, django, openapi, web, exploration]
    related_skills: [spike, research-protocol]
---

# Web API Discovery

## When to use

Use this skill when:
- A web page loads but shows an empty/blank interface (likely an SPA)
- You need to understand a web application's API without official docs
- You find a Django application — check for DEBUG=True mode
- A site uses JavaScript-heavy rendering but you want direct API access
- You have an auth token and want to explore what endpoints exist

## Core methodology

```
SPA page  →  find API base URL in JS bundles  →  enumerate endpoints  →  extract schema  →  explore
```

---

## Step 1: Identify the Application Type

First, check if the page is server-rendered or a client-side SPA:

```bash
# Check the raw HTML — look for <div id="app">, <script src="/assets/index-*.js">
curl -s "https://target.com/" | head -50
```

**Signs of an SPA:**
- Empty `<body>` with a single `<div id="app">` or `<div id="root">`
- A single `<script>` tag pointing to `/assets/index-<hash>.js`
- No meaningful HTML content (loaded via JavaScript)
- 200 HTTP response but empty page in the browser

## Step 2: Find the API Base URL

The API endpoint is usually NOT on the same hostname. Look for it in the JavaScript bundle.

### Method A: Check the axios/fetch config

```bash
# Download the main JS bundle
curl -s "https://target.com/assets/index-<hash>.js" > /tmp/bundle.js

# Search for axios/fetch base URL
grep -oP 'baseURL["\x60]\s*[:=]\s*["\x60][^"\x60]+["\x60]' /tmp/bundle.js

# Search for any URL containing "api"
grep -oP '["\x60](https?://[^"\x60]*api[^"\x60]*)["\x60]' /tmp/bundle.js
```

### Method B: Find the axios library import

SPAs using axios often have a separate chunk for it:

```bash
# Find axios chunk name
grep -oP '"assets/axios-[^"]*"' /tmp/bundle.js

# Download and inspect the axios config
curl -s "https://target.com/assets/axios-<hash>.js"
```

Then search within it for API base URLs using Python:

```python
import re
text = response_from_curl
matches = re.findall(r'["\x60]([^"\x60]{3,100}(?:api|v1|v2|rest)[^"\x60]{0,100})["\x60]', text)
```

### Method C: Check route chunk files

SPAs split code by route. Search for API patterns in route chunks:

```bash
# Extract chunk filenames from the main bundle
grep -oP '"[./][^"]*\.js"' /tmp/bundle.js | tr -d '"' | sort -u

# Search each chunk for API paths
for chunk in index new project app logs; do
  curl -s "https://target.com/assets/${chunk}-<hash>.js" | grep -oP '["'"'"'](/api/[^"'"'"' ]+)["'"'"']'
done
```

## Step 3: Enumerate Endpoints

### For Django REST Framework apps — use DEBUG mode

If the API is a Django app with `DEBUG=True` (visible in production — a common misconfiguration), visit a non-existent path to leak all URL patterns:

```bash
curl -s "https://api-target.com/api/nonexistent/" \
  -H "Authorization: Bearer <token>" \
  -H "Accept: application/json"
```

The 404 error page includes a numbered list of ALL registered URL patterns — every endpoint the API supports. This is the most comprehensive way to enumerate.

**Pitfall:** Some endpoints require specific sub-paths (like `/api/projects/projects/` instead of `/api/projects/`). Check the Django URL patterns for nested routers.

### Common Django REST Framework URL patterns

DRF routers create nested paths. First hit the root:

```bash
curl -s "https://api-target.com/api/" \
  -H "Authorization: Bearer <token>" \
  -H "Accept: application/json"
```

The root response lists available resource groups as hyperlinks:
```json
{
    "users": "https://api-target.com/api/auth/",
    "projects": "https://api-target.com/api/projects/",
    "apps": "https://api-target.com/api/apps/",
    "logs": "..."
}
```

Then explore each group — there may be further nesting:
```json
{
    "projects": "https://api-target.com/api/projects/projects/"
}
```

## Step 4: Extract the OpenAPI/Swagger Schema

If the API uses DRF with `drf-spectacular` or `drf-yasg`, it likely exposes a schema endpoint:

```bash
# OpenAPI 3.0 JSON schema
curl -s "https://api-target.com/api/schema/" \
  -H "Accept: application/json"

# Swagger UI
curl -s "https://api-target.com/api/swagger/"

# ReDoc
curl -s "https://api-target.com/api/redoc/"
```

The schema gives you every endpoint, method, parameter, and response format.

### Parse the schema

```python
import json

# Read the full schema
with open('schema.json') as f:
    data = json.load(f)

paths = data.get('paths', {})
for path, methods in sorted(paths.items()):
    for method, details in methods.items():
        tags = details.get('tags', [])
        desc = (details.get('description') or details.get('summary') or '')[:80]
        print(f'{method.upper():6s} {path}  {str(tags):30s} {desc}')
```

## Step 5: Token-Based Exploration

### Handling JWT tokens

JWT tokens often expire quickly (15-30 minutes). Look for mechanisms to refresh:

```bash
# Try the refresh endpoint
curl -s "https://api-target.com/api/auth/refresh/" \
  -X POST -H "Authorization: Bearer <refresh_token>"
```

If there's no refresh endpoint accessible, use the browser session to extract tokens from network traffic, or ask the user for a new token.

### Where tokens might be stored

In the browser:
- `localStorage.getItem('access_token')`
- `sessionStorage.getItem('token')`
- Cookies (check `document.cookie`)
- Vuex/Pinia store state
- HTTP-only cookies (not accessible via JS)

### For OAuth apps (GitHub, Google, etc.)

OAuth tokens usually have short lifetimes. The preferred approach when browser 2FA is tedious:

1. Ask the user for their **access token** JWT directly (if they can extract it from browser dev tools)
2. Use the token to explore API endpoints directly via curl
3. When it expires, ask for a new one

## Step 6: Map the Full API

Once you have the endpoint list, create a categorized reference:

| Category | Endpoints | Key Actions |
|----------|-----------|-------------|
| Auth | `/api/auth/`, `/api/auth/refresh/`, `/api/auth/users/me/` | Login, refresh, check user |
| Projects | `/api/projects/projects/` (CRUD) | Create, list, update, delete |
| Apps | `/api/apps/apps/`, `/*/redeploy/`, `/*/start/`, `/*/stop/` | Deploy, manage, scale |
| Services | `/api/apps/services/`, `/*/link/`, `/*/unlink/` | DB, Redis management |
| Logs | `/api/logs/app-runtime/`, `/api/logs/stream/{task_id}/` | Real-time logging |

Check the `description` field in the schema — it often contains critical context about permissions, side effects, and query parameters.

## Pitfalls

- **Token expiration**: JWT access tokens expire quickly. Work fast or use refresh tokens.
- **Subdomain routing**: The API may be on a completely different domain than the web UI. Always check JS bundles.
- **Nested routers**: DRF routers nest deep. Hit `/api/` first, then follow the links.
- **CORS restrictions**: Browser tools may fail due to CORS; use curl for direct API access.
- **HTTPS-only cookies**: Auth tokens may be in HTTP-only cookies, unreachable via JS. Use curl with `--cookie` flag.
- **Debug mode in production**: `DEBUG=True` is a security issue but useful for recon. Always report it.
- **Rate limiting**: Some APIs limit requests per token. Space out your requests.

## Reference files

- `references/fabroku-api-map.md` — Full endpoint map of the Fabroku platform (Dokku-based hosting), discovered using this methodology
