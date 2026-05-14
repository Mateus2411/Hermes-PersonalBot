# Thinking / Busy Indicator Architecture

Hermes Agent has **two separate systems** for showing "thinking" faces/indicators, depending on which UI mode is active. Both can be customized independently.

---

## 1. CLI KawaiiSpinner (classic terminal mode)

Used when running `hermes` (no `--tui` flag). Lives in the Python backend.

### Files

| File | Purpose |
|------|---------|
| `agent/display.py` (lines ~573-760) | `KawaiiSpinner` class — animated spinner with kawaii faces |

### Data

```python
# Lines 588-591
KAWAII_WAITING = [
    "(｡◕‿◕｡)", "(◕‿◕✿)", "٩(◕‿◕｡)۶", "(✿◠‿◠)", "( ˘▽˘)っ",
    "♪(´ε` )", "(◕ᴗ◕✿)", "ヾ(＾∇＾)", "(≧◡≦)", "(★ω★)",
]

# Lines 593-597
KAWAII_THINKING = [
    "(｡•́︿•̀｡)", "(◔_◔)", "(¬‿¬)", "( •_•)>⌐■-■", "(⌐■_■)",
    "(´･_･`)", "◉_◉", "(°ロ°)", "( ˘⌣˘)♡", "ヽ(>∀<☆)☆",
    "٩(๑❛ᴗ❛๑)۶", "(⊙_⊙)", "(¬_¬)", "( ͡° ͜ʖ ͡°)", "ಠ_ಠ",
]

# Lines 599-603
THINKING_VERBS = [
    "pondering", "contemplating", "musing", "cogitating", "ruminating",
    "deliberating", "mulling", "reflecting", "processing", "reasoning",
    "analyzing", "computing", "synthesizing", "formulating", "brainstorming",
]
```

### Customization via Skin (no code changes)

The `KawaiiSpinner` class checks the active skin FIRST (via `_get_skin()`) before falling back to the hardcoded lists. You can override these in `config.yaml`:

```yaml
display:
  skin:
    spinner:
      waiting_faces:
        - "(｡◕‿◕｡)"
        - "(★ω★)"
        # ... your custom faces
      thinking_faces:
        - "(｡•́︿•̀｡)"
        - "ಠ_ಠ"
        # ... your custom faces
      thinking_verbs:
        - "pondering"
        - "mulling"
        # ... your custom verbs
```

The lookup order:
1. `get_waiting_faces()` → `skin.spinner.waiting_faces` → `KAWAII_WAITING`
2. `get_thinking_faces()` → `skin.spinner.thinking_faces` → `KAWAII_THINKING`
3. `get_thinking_verbs()` → `skin.spinner.thinking_verbs` → `THINKING_VERBS`

### Spinner frame types

Defined as `KawaiiSpinner.SPINNERS` (line 576-586):
- `'dots'` — braille dots
- `'bounce'` — bouncing braille
- `'grow'` — growing block
- `'arrows'` — directional arrows
- `'star'` — asterisk variants
- `'moon'` — moon phase emojis
- `'pulse'` — half-circle pulse
- `'brain'` — brain/thought emoji sequence
- `'sparkle'` — sparkle unicode

---

## 2. TUI/Ink Indicator (React terminal UI)

Used when running `hermes --tui`. Switchable at runtime via `/indicator [style]`. Four built-in styles: `kaomoji`, `emoji`, `unicode`, `ascii`.

### Files

| File | Purpose |
|------|---------|
| `ui-tui/src/app/interfaces.ts` (line 37-38) | `INDICATOR_STYLES` array and `IndicatorStyle` type — add new styles here |
| `ui-tui/src/app/uiStore.ts` (line 16) | Default indicator style |
| `ui-tui/src/app/useConfigSync.ts` (line 60-68) | `normalizeIndicatorStyle()` — normalizes config value to valid style |
| `ui-tui/src/components/appChrome.tsx` (lines 30-75) | `renderIndicator()` — maps style → frame + verb visibility |
| `ui-tui/src/content/faces.ts` | `FACES` array — the kaomoji strings used by `kaomoji` style |
| `ui-tui/src/content/verbs.ts` | `VERBS` array — English verb rotation |
| `tui_gateway/server.py` (lines 648-649) | Python-side `_INDICATOR_STYLES` tuple and `_INDICATOR_DEFAULT` |
| `tui_gateway/server.py` (line 3956) | Writes to config key `display.tui_status_indicator` |
| `hermes_cli/config.py` (line 922) | Default config value `tui_status_indicator: "kaomoji"` |
| `cli-config.yaml.example` (line ~586+) | Config example |

### Data

**FACES** (`ui-tui/src/content/faces.ts`):
```typescript
export const FACES = [
  '(｡•́︿•̀｡)', '(◔_◔)', '(¬‿¬)', '( •_•)>⌐■-■', '(⌐■_■)',
  '(´･_･`)', '◉_◉', '(°ロ°)', '( ˘⌣˘)♡', 'ヽ(>∀<☆)☆',
  '٩(๑❛ᴗ❛๑)۶', '(⊙_⊙)', '(¬_¬)', '( ͡° ͜ʖ ͡°)', 'ಠ_ಠ',
]
```

**VERBS** (`ui-tui/src/content/verbs.ts`):
```typescript
export const VERBS = [
  'pondering', 'contemplating', 'musing', 'cogitating', 'ruminating',
  'deliberating', 'mulling', 'reflecting', 'processing', 'reasoning',
  'analyzing', 'computing', 'synthesizing', 'formulating', 'brainstorming',
]
```

**EMOJI_FRAMES** (`ui-tui/src/components/appChrome.tsx` line 30):
```typescript
const EMOJI_FRAMES = ['⚕ ', '🌀', '🤔', '✨', '🍵', '🔮']
```

**ASCII_FRAMES** (`ui-tui/src/components/appChrome.tsx` line 31):
```typescript
const ASCII_FRAMES = ['|', '/', '-', '\\']
```

The `unicode` style uses the `unicode-animations` npm package (`unicodeSpinners.braille`).

### The `renderIndicator()` function (appChrome.tsx lines 47-76)

```typescript
const renderIndicator = (style: IndicatorStyle, tick: number): IndicatorRender => {
  if (style === 'kaomoji') {
    return { frame: FACES[tick % FACES.length], intervalMs: FACE_TICK_MS, showVerb: true }
  }
  if (style === 'emoji') {
    return { frame: EMOJI_FRAMES[tick % EMOJI_FRAMES.length], intervalMs: SPINNER_TICK_MS * 6, showVerb: true }
  }
  if (style === 'ascii') {
    return { frame: ASCII_FRAMES[tick % ASCII_FRAMES.length], intervalMs: SPINNER_TICK_MS, showVerb: true }
  }
  // unicode — braille spinner, no verb
  const spinner = unicodeSpinners.braille
  return { frame: spinner.frames[tick % spinner.frames.length], intervalMs: ..., showVerb: false }
}
```

---

## How to Add a New Indicator Style (TUI)

1. Add the style name to `INDICATOR_STYLES` in `ui-tui/src/app/interfaces.ts`
2. Add an `if (style === 'your-style')` branch in `renderIndicator()` in `appChrome.tsx`
3. Add default to `normalizeIndicatorStyle()` test in `ui-tui/src/__tests__/useConfigSync.test.ts`
4. Update `_INDICATOR_STYLES` tuple in `tui_gateway/server.py`

No gateway restart needed — `/indicator your-style` reads from config live.

---

## How to Modify Existing Faces

| System | File | Edit |
|--------|------|------|
| CLI (kawaii) | `agent/display.py` lines 588-603 | `KAWAII_WAITING`, `KAWAII_THINKING`, `THINKING_VERBS` |
| CLI (skin) | `config.yaml` | `display.skin.spinner.waiting_faces`, etc. |
| TUI faces | `ui-tui/src/content/faces.ts` | `FACES` array |
| TUI verbs | `ui-tui/src/content/verbs.ts` | `VERBS` array |
| TUI emoji frames | `ui-tui/src/components/appChrome.tsx` line 30 | `EMOJI_FRAMES` |
| TUI ascii frames | `ui-tui/src/components/appChrome.tsx` line 31 | `ASCII_FRAMES` |

---

## Config Key

```
display.tui_status_indicator: kaomoji   # kaomoji | emoji | unicode | ascii
```

Set via:
- `hermes config set display.tui_status_indicator emoji`
- `/indicator emoji` (live switch in TUI session)
