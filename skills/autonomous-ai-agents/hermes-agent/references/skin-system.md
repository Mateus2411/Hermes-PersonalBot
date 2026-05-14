# Hermes Agent Skin System

The skin system (`hermes_cli/skin_engine.py`) lets users customize the CLI's visual appearance — colors, spinner animations, branding text, banner art, and tool prefix. Skins can be built-in (hardcoded in `_BUILTIN_SKINS`) or user-defined (YAML files in `~/.hermes/skins/`).

**Activation:** `/skin <name>` in-session, or `display.skin: <name>` in `config.yaml`.

---

## Architecture

### SkinConfig dataclass (`skin_engine.py`)

```python
@dataclass
class SkinConfig:
    name: str
    description: str = ""
    colors: Dict[str, str] = field(default_factory=dict)
    spinner: Dict[str, Any] = field(default_factory=dict)
    branding: Dict[str, str] = field(default_factory=dict)
    tool_prefix: str = "┊"
    tool_emojis: Dict[str, str] = field(default_factory=dict)
    banner_logo: str = ""     # Rich-markup ASCII art logo
    banner_hero: str = ""     # Rich-markup hero art
```

### Built-in skins: `_BUILTIN_SKINS` dict

Defined starting around line 170 of `skin_engine.py`. Each key is the skin name, value is a dict following the YAML schema. The dict ends around line 646 (before `load_skin` / management functions).

### Merge behavior

When a skin is loaded, `_build_skin_config()` does a **shallow merge** over the `default` skin:

```python
colors = dict(default.get("colors", {}))
colors.update(data.get("colors", {}))    # skin values override default
spinner = dict(default.get("spinner", {}))
spinner.update(data.get("spinner", {}))
branding = dict(default.get("branding", {}))
branding.update(data.get("branding", {}))
```

So a skin only needs to specify what it differs from default. Missing fields inherit from default.

---

## Skin Schema — All Fields

### `colors`

| Key | Purpose | Default |
|-----|---------|---------|
| `banner_border` | Panel border | `#CD7F32` |
| `banner_title` | Panel title text | `#FFD700` |
| `banner_accent` | Section headers (Available Tools, etc.) | `#FFBF00` |
| `banner_dim` | Dim/muted text (separators, labels) | `#B8860B` |
| `banner_text` | Body text (tool names, skill names) | `#FFF8DC` |
| `ui_accent` | General UI accent | `#FFBF00` |
| `ui_label` | UI labels | `#DAA520` |
| `ui_ok` | Success indicators | `#4caf50` |
| `ui_error` | Error indicators | `#ef5350` |
| `ui_warn` | Warning indicators | `#ffa726` |
| `prompt` | Prompt text color | `#FFF8DC` |
| `input_rule` | Input area horizontal rule | `#CD7F32` |
| `response_border` | Response box border | `#FFD700` |
| `status_bar_bg` | Status bar background | `#1a1a2e` |
| `status_bar_text` | Status bar default text | auto-falls to banner_text |
| `status_bar_strong` | Status bar highlighted text | auto-falls to banner_title |
| `status_bar_dim` | Status bar separators/muted | auto-falls to banner_dim |
| `status_bar_good` | Healthy context usage | `#8FBC8F` |
| `status_bar_warn` | Warning context usage | auto-falls to ui_warn |
| `status_bar_bad` | High context usage | auto-falls to banner_accent |
| `status_bar_critical` | Critical context usage | auto-falls to ui_error |
| `session_label` | Session label color | auto-falls to ui_label |
| `session_border` | Session ID dim color | auto-falls to banner_dim |
| `voice_status_bg` | TUI voice status bg | auto-falls to status_bar_bg |
| `selection_bg` | TUI mouse-selection bg | auto-falls to `#333355` |
| `completion_menu_bg` | Completion menu bg | auto-falls to status_bar_bg |
| `completion_menu_current_bg` | Active completion row | auto-falls to `#333355` |
| `completion_menu_meta_bg` | Meta column bg | auto-falls to menu_bg |
| `completion_menu_meta_current_bg` | Active meta bg | auto-falls to menu_current_bg |

The `_build_skin_config()` merges over `default` colors, but `get_prompt_toolkit_style_overrides()` adds its own fallback chain (e.g., `status_bar_text` falls back to `text` which falls back to `prompt`). Double-layered fallback ensures no undefined values reach prompt_toolkit.

### `spinner`

| Sub-field | Type | Purpose |
|-----------|------|---------|
| `waiting_faces` | `List[str]` | Faces cycled while waiting for API (shorter cycle) |
| `thinking_faces` | `List[str]` | Faces cycled during reasoning/thinking |
| `thinking_verbs` | `List[str]` | Verb phrases shown in spinner messages, e.g. "forging", "holding the line" |
| `wings` | `List[List[str]]` | Left/right decorations, each entry is `[left, right]` pair |

**Difference between waiting and thinking:** They're used at different stages of a request. The spinner engine picks from `waiting_faces` during the initial API wait and `thinking_faces` when the model is in a reasoning state. Both are independent lists — a skin can have different faces for each stage or reuse the same ones.

**Thinking verbs** are injected into spinner messages like `"⟪🔥 waiting_face 🔥⟫ thinking_verb..."` (paraphrasing — actual format depends on CLI spinner rendering). The verb gives context to what the agent is doing.

**Wings** are displayed flanking the current face. The spinner engine cycles through both faces and wings independently, creating visual variety. Each entry is a 2-element list `[left_decoration, right_decoration]`.

**Default:** The default skin has an empty spinner dict `# Empty = use hardcoded defaults in display.py`. Custom skins should provide all four fields for visual consistency.

### `branding`

| Key | Purpose |
|-----|---------|
| `agent_name` | Banner title, status display |
| `welcome` | Shown at CLI startup |
| `goodbye` | Shown on exit |
| `response_label` | Response box header label |
| `prompt_symbol` | Input prompt symbol (bare token; renderers add trailing space) |
| `help_header` | `/help` header text |

### `tool_prefix`

A single character used as prefix for tool output lines. Default: `┊`.

### `tool_emojis`

Per-tool emoji overrides in the spinner/progress display:
```yaml
tool_emojis:
  terminal: "⚔"
  web_search: "🔮"
```

Any tool not listed uses its registry default.

### `banner_logo` / `banner_hero`

Rich-markup ASCII art strings. Both are optional.

- `banner_logo`: Replaces `HERMES_AGENT_LOGO` in the banner (typically the "AGENT" text logo in ASCII).
- `banner_hero`: Replaces `HERMES_CADUCEUS` (the decorative ASCII art below the logo).

Both use Rich markup with inline color tags: `[bold #FFD700]text[/]` or `[#HEXCOLOR]text[/]`. Line breaks use `\n`. Triple-quoted raw strings in Python (`"""..."""`) keep the line breaks literal.

Gradients can be achieved by using a different color per line.

**Character limit warning:** Skin entries in `_BUILTIN_SKINS` are Python dicts, so multiline strings use three levels of indentation. Keep banner art compact (6-10 lines for the logo, 8-14 lines for the hero) to avoid ballooning the file.

---

## Adding a Built-in Skin

To add a new built-in skin (hardcoded in `_BUILTIN_SKINS`):

1. **Open** `~/.hermes/hermes-agent/hermes_cli/skin_engine.py`
2. **Locate** `_BUILTIN_SKINS` (starts ~line 170, ends ~line 646)
3. **Add** a new entry after the last skin, before the closing `}` of the dict
4. **Skin entry structure** (follow the `charizard` skin as the most complete template):

```python
"your-skin-name": {
    "name": "your-skin-name",
    "description": "Short description shown in /skin listing",
    "colors": {
        # override colors as needed — missing keys inherit from default
        "banner_border": "#HEXCODE",
        "banner_title": "#HEXCODE",
        ...
    },
    "spinner": {
        "waiting_faces": ["(face1)", "(face2)", ...],
        "thinking_faces": ["(face1)", "(face2)", ...],
        "thinking_verbs": [
            "verb phrase 1",
            "verb phrase 2",
            ...
        ],
        "wings": [
            ["⟪decoration1", "decoration1⟫"],
            ["⟪decoration2", "decoration2⟫"],
        ],
    },
    "branding": {
        "agent_name": "Your Skin Agent",
        "welcome": "Welcome message shown at startup",
        "goodbye": "Goodbye! ❖",
        "response_label": " ❖ Your Skin Name ",
        "prompt_symbol": "❖",
        "help_header": "(❖) Available Commands",
    },
    "tool_prefix": "│",
    "banner_logo": "[bold #HEXCODE]ASCII ART[/]\n...",  # optional
    "banner_hero": """[#HEXCODE]ASCII ART[/]...""",      # optional
}
```

5. **Update the docstring** (lines ~98-115) to list the new skin
6. **Verify** with Python:
   ```python
   from hermes_cli.skin_engine import load_skin, list_skins
   print(list_skins())  # should show new skin
   s = load_skin("your-skin-name")  # should not raise
   print(s.spinner, s.colors, s.branding)  # inspect
   ```

### Pitfalls

- **Escape-drift in patch tool:** When using `patch` tool to insert a skin, ensure old_string and new_string contain **exact** Python dict syntax without spurious backslash escapes. The patch tool escapes `\"` automatically in JSON parameter serialization — if you see `\"` in your patch strings where the file has `"`, that's a serialization artifact. Use plain `"` in old_string/new_string, not `\"`.

- **Docstring update separately:** The docstring and the `_BUILTIN_SKINS` dict are separate parts of the file. They must be updated independently (or in the same patch if the replacement region covers both).

- **Duplicate skin names:** If a user YAML skin in `~/.hermes/skins/` has the same name as a built-in, the user skin takes precedence (loaded first in `load_skin()`).

- **Color contrast on dark/light terminals:** Test your skin on both dark and light terminal backgrounds. The `daylight` and `warm-lightmode` skins are reference implementations for light-background compatibility (they override `status_bar_bg`, `voice_status_bg`, `completion_menu_*` with light colors).

- **`_BUILTIN_SKINS` insertion point:** The dict closes on the line after the last skin entry. Insert new entries **before** the closing `}` of the `_BUILTIN_SKINS` dict (after `charizard` if that's the last entry, ~line 646).

---

## User Skins (YAML)

Drop a YAML file in `~/.hermes/skins/<name>.yaml` following the same schema. No code changes needed. The YAML file uses the same nested structure as the Python dict (without Python syntax, of course).

```yaml
name: mytheme
description: Short description
colors:
  banner_border: "#CD7F32"
  banner_title: "#FFD700"
  ...
spinner:
  waiting_faces: ["(⚔)", "(⛨)"]
  thinking_faces: ["(⌁)", "(<>)"]
  thinking_verbs:
    - forging
    - plotting
  wings:
    - ["⟪⚔", "⚔⟫"]
    - ["⟪▲", "▲⟫"]
branding:
  agent_name: Hermes Agent
  welcome: Welcome!
  goodbye: Goodbye!
  response_label: " ⚕ Hermes "
  prompt_symbol: "❯"
  help_header: "(^_^)? Commands"
tool_prefix: "┊"
tool_emojis:
  terminal: "⚔"
  web_search: "🔮"
```

---

## Existing Built-in Skins Summary

| Name | Theme | Colors |
|------|-------|--------|
| `default` | Classic Hermes gold/kawaii | Gold, cream, dark navy |
| `ares` | War-god crimson/bronze | Dark red, bronze, crimson |
| `mono` | Clean grayscale | 50 grays from #F5F5F5 to #444 |
| `slate` | Cool blue developer | Royal blue, ice blue, slate |
| `daylight` | Light bg with blue accents | Light bg, dark text, blue |
| `warm-lightmode` | Warm brown/gold for light bg | Brown, gold, warm cream |
| `poseidon` | Ocean-god deep blue/seafoam | Navy, seafoam, light blue |
| `sisyphus` | Austere grayscale/persistence | Stepped grays, boulder motif |
| `charizard` | Volcanic burnt orange/ember | Orange, gold, dark rust |
| `picante` | Red/orange spicy, pt-BR | Red, orange, pimenta |
| `filha-da-puta` | Aggressive blood red/black/purple | Blood red, dark black, purple |
| `kwai-picante` | Neon green/pink/blue chaos, pt-BR | Neon green, hot pink, electric blue |
