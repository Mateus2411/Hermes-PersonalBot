# Fabroku API (Dokku-based Hosting Platform)

**Discovered:** 2026-05-10 via web-api-discovery methodology

**Web UI:** https://fabroku.fabricadesoftware.ifc.edu.br/dashboard
**API Base:** https://fabroku-api.fabricadesoftware.ifc.edu.br/api/
**Auth:** GitHub OAuth via JWT (access token, 15min expiry)
**Framework:** Django REST Framework (DEBUG=True in production)
**Backend:** Dokku (Docker container deployment)

## Discovery Path

1. Web UI returned empty SPA page (Vue 3 + Vuetify + Vite)
2. Main JS bundle (`/assets/index-B9zlI8oV.js`) imported axios from `/assets/axios-CEsReAwQ.js`
3. Axios config revealed `baseURL: "https://fabroku-api.fabricadesoftware.ifc.edu.br/api"`
4. Visiting a nonexistent path returned Django 404 with `DEBUG=True`, leaking all URL patterns
5. Full OpenAPI 3.0 schema available at `/api/schema/` (164KB)
6. 62 endpoint paths documented

## Key Endpoints

### Auth
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/auth/` | Auth root |
| GET | `/api/auth/check/` | Verify authentication, returns user data |
| GET | `/api/auth/github/login/` | GitHub OAuth login |
| GET | `/api/auth/github/callback/` | OAuth callback |
| GET | `/api/auth/cli/login/` | CLI OAuth flow |
| POST | `/api/auth/refresh/` | Refresh JWT using refresh_token cookie |
| POST | `/api/auth/logout/` | Logout, clear cookies |
| GET | `/api/auth/users/me/` | Current user profile |
| GET | `/api/auth/users/` | User list (paginated) |
| GET | `/api/auth/users/admin_list/` | All users (admin only) |
| GET | `/api/auth/users/my_quota/` | Quota info (apps/services limits) |
| POST | `/api/auth/users/{id}/toggle_active/` | Toggle user active (admin) |
| POST | `/api/auth/users/{id}/toggle_admin/` | Toggle admin (admin) |
| POST | `/api/auth/users/{id}/set_quota/` | Set custom limits (admin) |

### Projects
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/projects/` | Projects root |
| GET | `/api/projects/projects/` | List projects |
| POST | `/api/projects/projects/` | Create project |
| GET | `/api/projects/projects/{id}/` | Project detail |
| PATCH/PUT/DELETE | `/api/projects/projects/{id}/` | Update/Delete project |

### Apps
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/apps/` | Apps root |
| GET | `/api/apps/apps/` | List apps |
| POST | `/api/apps/apps/` | Create app |
| GET | `/api/apps/apps/{id}/` | App detail |
| GET | `/api/apps/apps/check_name/` | Check app name availability |
| GET | `/api/apps/apps/{id}/allowed_commands/` | List allowed run commands |
| GET | `/api/apps/apps/{id}/last_commit/` | Last deployed commit |
| GET | `/api/apps/apps/{id}/processes/` | Process scale info |
| GET | `/api/apps/apps/{id}/get_app_status/` | App status |
| GET | `/api/apps/apps/{id}/diagnose_webhook/` | Webhook & commit status diagnosis |
| GET | `/api/apps/apps/{id}/artifacts/{artifact_id}/download/` | Download dumpdata artifact |
| POST | `/api/apps/apps/{id}/deploy/` | Deploy app |
| POST | `/api/apps/apps/{id}/redeploy/` | Manual redeploy (re-sync with Git) |
| POST | `/api/apps/apps/{id}/restart/` | Restart app |
| POST | `/api/apps/apps/{id}/start/` | Start stopped app |
| POST | `/api/apps/apps/{id}/stop/` | Stop running app / cancel redeploy |
| POST | `/api/apps/apps/{id}/run_command/` | Execute command in container |
| POST | `/api/apps/apps/{id}/scale_processes/` | Scale persistent processes |
| POST | `/api/apps/apps/{id}/setup_webhook/` | Create/verify GitHub webhook |
| POST | `/api/apps/apps/{id}/test_commit_status/` | Test GitHub commit status |
| POST | `/api/apps/apps/{id}/run_dumpdata/` | Django dumpdata -> artifact |
| POST | `/api/apps/apps/{id}/run_loaddata/` | Load JSON fixture via loaddata |
| POST | `/api/apps/apps/{id}/interactive_sessions/` | Start CLI interactive session |
| POST | `/api/apps/apps/{id}/interactive_sessions/{sid}/answer/` | Send answer to prompt |
| POST | `/api/apps/apps/{id}/interactive_sessions/{sid}/cancel/` | Cancel session |
| GET | `/api/apps/apps/{id}/interactive_sessions/{sid}/events/` | SSE event stream |

### Services (DB, Redis, etc.)
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/apps/services/` | List services |
| POST | `/api/apps/services/` | Create service |
| GET | `/api/apps/services/{id}/` | Service detail |
| GET | `/api/apps/services/{id}/get_service_status/` | Task status (create/link/unlink/delete) |
| POST | `/api/apps/services/{id}/link/` | Link service to app |
| POST | `/api/apps/services/{id}/unlink/` | Unlink service from app |
| DELETE | `/api/apps/services/{id}/` | Delete service |

### Logs
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/logs/` | Logs root |
| GET | `/api/logs/app-runtime/` | Real-time container logs (stdout/stderr) |
| GET | `/api/logs/app-runtime/?app={app_id}&num={N}` | Filter by app, limit lines |
| GET | `/api/logs/stream/{task_id}/` | Polling-based log streaming |
| GET | `/api/logs/{id}/` | Log detail |

### Git
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/git/repos` | Git repos |

### Webhooks
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/webhooks/github/{app_id}/` | GitHub webhook receiver (auto-deploy on push) |

### Admin
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/admin-api/storage-usage/` | Postgres storage usage per project/service |

### Allowed Emails (admin)
| Method | Path | Description |
|--------|------|-------------|
| GET/POST | `/api/allowed-emails/` | List/Create allowed emails |
| GET/PATCH/PUT/DELETE | `/api/allowed-emails/{id}/` | Email detail |
| GET | `/api/allowed-emails/check_email/` | Check if email is allowed |
| POST | `/api/allowed-emails/bulk_create/` | Bulk create emails |
| POST | `/api/allowed-emails/{id}/toggle_active/` | Toggle email active |

## Authentication Flow

1. User clicks "Entrar com GitHub" on web UI
2. Redirects to GitHub OAuth (requires 2FA approval on mobile)
3. GitHub redirects back to `/api/auth/github/callback/`
4. Backend creates JWT access token (15min expiry) and refresh token
5. Tokens stored in HTTP-only cookies or returned to SPA
6. `/api/auth/refresh/` renews access token using refresh_token cookie
7. CLI login available at `/api/auth/cli/login/` with port parameter

## User Data (from session)

| Field | Value |
|-------|-------|
| User ID | 205017781 |
| GitHub login | Mateus2411 |
| Email | mateushenriquedasilva2411@gmail.com |
| Project | "Minha AI: Hermes" (UUID: 636866f2-...) |
| Project users | 1 (self only) |

## Tips

- Token expiry is 15 minutes (iat→exp = 900s)
- The API accepts Bearer token via `Authorization: Bearer <jwt>` header
- Always send `Accept: application/json` header to get JSON, not HTML
- Django DEBUG mode is ON in production — routes are enumerable via 404 pages
- OpenAPI schema at `/api/schema/` is the single source of truth
