# Programmatic CLI Output

How Hermes CLI commands return data and how to parse it when building custom tools or UIs that call `hermes` as a subprocess.

## No JSON Output

The Hermes CLI does **not** have a `--json` or `--format json` flag on any subcommand (`skills list`, `tools list`, `mcp list`, `config`, `status`). All data is rendered as Unicode box-drawing tables or freeform text. You must parse the terminal output.

## Parsing the Box-Drawing Tables

Commands that produce tables use Unicode box-drawing characters (U+2500–U+257F):

| Command | What to parse |
|---------|---------------|
| `hermes skills list` | Rows separated by `┃` (U+2503) |
| `hermes tools list` | Lines like `✓ enabled  toolname  description` |
| `hermes mcp list`   | Rows separated by `│` (U+2502) |
| `hermes config`     | Key: value pairs, some nested YAML |

### Skills List Strategy

```
┏━━━━━━━━━━━━┳━━━━━━━━━━━━┳━━━━━━━━━┳━━━━━━━━┓
┃ Name       ┃ Category   ┃ Source  ┃ Status ┃
┡━━━━━━━━━━━━╇━━━━━━━━━━━━╇━━━━━━━━━╇━━━━━━━━┩
│ skill-name │ category   │ builtin │ enabled│
└────────────┴────────────┴─────────┴────────┘
```

Algorithm:
1. Skip lines with `┏`, `┡`, `┗`, `└`, `├` — those are frame borders
2. Split data lines on `┃` (U+2503) or `│` (U+2502)
3. Filter out empty segments, trim each field

In Node.js:
```js
function parseSkillsTable(output) {
  const items = [];
  for (const line of output.split('\n')) {
    if (!line.includes('┃')) continue;
    const parts = line.split('┃').filter(p => p.trim());
    if (parts.length >= 2) {
      items.push({
        name: parts[0].trim(),
        category: parts[1].trim(),
        source: parts[2]?.trim() || '',
        status: parts[3]?.trim() || '',
      });
    }
  }
  return items;
}
```

In Python:
```python
def parse_skills(output):
    items = []
    for line in output.splitlines():
        if '┃' not in line:
            continue
        parts = [p.strip() for p in line.split('┃') if p.strip()]
        if len(parts) >= 2:
            items.append({
                'name': parts[0],
                'category': parts[1],
                'source': parts[2] if len(parts) > 2 else '',
            })
    return items
```

### Tools List Strategy

Output looks like:
```
  ✓ enabled  web  🔍 Web Search & Scraping
  ✓ enabled  terminal  💻 Terminal & Processes
  ✗ disabled  homeassistant  🏠 Home Assistant
```

Regex approach (Node.js):
```js
const match = line.match(/(✓|✗)\s+(enabled|disabled)\s+(\S+)\s+(.+)/);
```

### MCP List Strategy

Output looks like:
```
  Name             Transport                      Tools        Status
  ──────────────── ────────────────────────────── ──────────── ──────────
  youtube-transcript npx @fabriqa.ai/youtube-t...   all          ✓ enabled
```

Split on `│` or use fixed-width column positions based on the header markers.

### Config & Status (Freeform Text)

`hermes config` and `hermes status --all` output is freeform text with emoji indicators and `◆` info bullets. No reliable programmatic parse — best used for display-only or matched via simple grep/keyword search.

## Critical: `hermes chat -q` Timeout

**`hermes chat -q "..."` calls the LLM and can take 30–120+ seconds.** The default `terminal` tool timeout is 180s, but when calling from a subprocess, the command will hang until the LLM finishes processing.

Best practices:
- Set a **120s+ timeout** on the subprocess when calling `hermes chat -q`
- Use the `--quiet` flag (`-Q`) to suppress spinner, banner, and tool previews
- Consider using `--yolo` if you need to skip approval prompts in automated contexts
- If the command times out, the subprocess will return exit code 124 (SIGALRM on Linux)
- **Do NOT use `hermes chat -q`** for simple listing queries (`/skills`, `/tools`, etc.) — those can be answered by parsing CLI output directly, which completes in <1s

## Fast CLI Commands (No LLM Needed)

These all return in <1 second and are safe for programmatic calls:

| Command | Returns | Parse strategy |
|---------|---------|---------------|
| `hermes skills list` | Table of all skills | Box-drawing split (above) |
| `hermes tools list` | List of toolsets with + icons | Regex per line |
| `hermes mcp list` | Table of MCP servers | Box-drawing split |
| `hermes config` | Config overview | Freeform text display |
| `hermes status --all` | Status info | Freeform text display |
| `hermes --version` | Version string | First line is version |

## Filesystem-Direct Backend (Fast, No CLI)

For building a custom Hermes UI or dashboard, **bypass the CLI entirely** by reading filesystem structures directly. This drops response time from ~800ms (CLI spawn) to ~2ms (direct read).

### Skills: Directory Structure

The skills directory at `~/.hermes/skills/` has two layouts:

```
~/.hermes/skills/
├── category-name/              # Option A: flat MD files per skill
│   ├── skill-one.md
│   └── skill-two.md
└── another-category/           # Option B: subdirectory with SKILL.md
    ├── nested-skill/
    │   └── SKILL.md
    └── another-nested/
        ├── SKILL.md
        └── references/
```

Node.js scanner:
```js
function scanSkills() {
  const items = [];
  const HERMES_SKILLS = path.join(homedir(), '.hermes', 'skills');
  if (!existsSync(HERMES_SKILLS)) return items;

  const entries = readdirSync(HERMES_SKILLS, { withFileTypes: true });
  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    const catPath = path.join(HERMES_SKILLS, entry.name);
    const skillEntries = readdirSync(catPath, { withFileTypes: true });
    for (const se of skillEntries) {
      const fullPath = path.join(catPath, se.name);
      if (se.isDirectory() && existsSync(path.join(fullPath, 'SKILL.md'))) {
        // category/subdir/SKILL.md
        items.push({ name: se.name, category: entry.name, source: 'local', status: 'enabled' });
      } else if (se.isFile() && se.name.endsWith('.md') && se.name !== 'SKILL.md') {
        // category/skill-name.md
        items.push({
          name: se.name.replace(/\.md$/, ''),
          category: entry.name,
          source: 'local',
          status: 'enabled',
        });
      }
    }
  }
  return items;
}
```

### Config: Direct YAML Read

```js
function readConfig() {
  const configPath = path.join(homedir(), '.hermes', 'config.yaml');
  if (existsSync(configPath)) {
    return readFileSync(configPath, 'utf-8');
  }
  // Fallback to CLI
  return execSync('hermes config 2>&1', { encoding: 'utf-8', timeout: 5000 });
}
```

### Skill Detail: Filesystem Search

```js
function findSkill(name) {
  const HERMES_SKILLS = path.join(homedir(), '.hermes', 'skills');
  if (!existsSync(HERMES_SKILLS)) return null;

  const entries = readdirSync(HERMES_SKILLS, { withFileTypes: true });
  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    const catPath = path.join(HERMES_SKILLS, entry.name);
    // Try: category/skill-name.md
    const flatPath = path.join(catPath, `${name}.md`);
    if (existsSync(flatPath)) return readFileSync(flatPath, 'utf-8');
    // Try: category/skill-name/SKILL.md
    const nestedPath = path.join(catPath, name, 'SKILL.md');
    if (existsSync(nestedPath)) return readFileSync(nestedPath, 'utf-8');
  }
  return null; // fallback to `hermes skills inspect NAME`
}
```

### TTL Caching Pattern (for CLI-dependent data)

For endpoints that still need the CLI (tools list, MCP list, status), wrap with an in-memory TTL cache. This way the first call pays the CLI cost, subsequent calls within the TTL window return instantly.

```js
const cache = new Map();

function cached(key, ttlMs, fetcher) {
  const now = Date.now();
  const entry = cache.get(key);
  if (entry && now - entry.timestamp < ttlMs) return entry.data;
  const data = fetcher();
  cache.set(key, { data, timestamp: now });
  return data;
}

// Usage:
app.get('/api/tools', (req, res) => {
  const tools = cached('tools', 30000, () => {
    return execSync('hermes tools list 2>&1', { encoding: 'utf-8', timeout: 10000 });
  });
  res.json({ tools });
});
```

Add a refresh endpoint so the UI can invalidate on demand:
```js
app.get('/api/refresh', (req, res) => {
  const key = req.query.key;
  if (key && cache.has(key)) { cache.delete(key); return res.json({ ok: true, cleared: key }); }
  cache.clear();
  res.json({ ok: true, cleared: 'all' });
});
```

### Terminal Builtins (Instant, No Spawn)

When building a terminal-like interface, handle built-in commands server-side without spawning `hermes` at all:

| Command | Source | Implementation |
|---------|--------|----------------|
| `/help` | Static | Hardcoded help text |
| `/skills` | Filesystem | `scanSkills()` (~2ms) |
| `/config` | Filesystem | `readConfig()` (~1ms) |
| `/tools` | Cache | TTL cache (30s) |
| `/mcp` | Cache | TTL cache (30s) |
| `/status` | Cache | TTL cache (30s) |
| `/skill X` | Filesystem | `findSkill(name)` (~2ms) |
| `/clear` | Static | Return empty output |
| Free text | CLI async | `hermes chat -q TEXTO --quiet` (LLM call, 120s timeout) |

This means all but "free text" queries are **instant** — no CLI process spawns.

### Composite Endpoint

Assemble system info from multiple sources for a dashboard's status bar:

```js
app.get('/api/info', (req, res) => {
  const skills = scanSkills();
  const ver = execSync('hermes --version 2>&1', { encoding: 'utf-8', timeout: 5000 }).trim();
  const mcpData = cached('mcp', 30000, () => hermes('mcp list').data || '');
  const mcpCount = mcpData.split('\n').filter(l => l.includes('npx') || l.includes('http')).length;

  res.json({
    version: ver,
    platform: process.platform,
    hostname: execSync('hostname 2>&1', { encoding: 'utf-8', timeout: 3000 }).trim(),
    skillCount: skills.length,
    skillCategories: new Set(skills.map(s => s.category).filter(Boolean)).size,
    mcpCount,
  });
});
```

### MCP Server Config

MCP server config is in `~/.hermes/config.yaml` under the `mcp_servers:` key. Read it via the YAML-read function above and parse with a YAML library if you need structured access (e.g., to list transports and tool counts).

### Sidebar Toggle Positioning (Vue)

When building a sidebar with a collapse toggle button, anchor the toggle to the **sidebar itself** as a child, not to the viewport:

```vue
<aside class="sidebar" :class="{ collapsed }">
  <button class="sidebar-toggle" @click="collapsed = !collapsed">
    {{ collapsed ? '▶' : '◀' }}
  </button>
  <!-- ...sidebar content... -->
</aside>
```

```css
.sidebar {
  position: relative;
  width: 220px;
  transition: width 0.2s;
}
.sidebar.collapsed {
  width: 52px;
}
.sidebar-toggle {
  position: absolute;
  top: 50%;
  right: -10px;               /* hangs halfway outside the right edge */
  transform: translateY(-50%);
  width: 22px;
  height: 44px;
  border-radius: 0 6px 6px 0;
  border-left-color: transparent; /* blends with sidebar border */
  cursor: pointer;
  z-index: 100;
}
/* When collapsed, adjust so it still sits on the new edge */
.sidebar.collapsed .sidebar-toggle {
  right: -11px;
}
```

Key principle: **absolute positioning relative to the sidebar**, not `position: fixed` relative to the viewport. The toggle moves naturally when the sidebar width transitions, with no sibling-selector gymnastics.

## Built-in Dashboard

Hermes has a built-in web dashboard at port 9119:

```bash
hermes dashboard                       # Start dashboard
hermes dashboard --tui                 # With in-browser terminal chat
hermes dashboard --port 8080           # Custom port
hermes dashboard --insecure            # Allow external access (⚠ exposes API keys!)
hermes dashboard --status              # Check if running
hermes dashboard --stop                # Stop all dashboard processes
```

This is a separate Node.js-based app bundled with Hermes, not to be confused with custom UIs built against the CLI.
