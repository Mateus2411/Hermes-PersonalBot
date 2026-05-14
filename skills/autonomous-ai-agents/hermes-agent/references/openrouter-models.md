# OpenRouter Verified Model IDs

Verified working model IDs for this user's setup. No suffixes — use exactly as listed.

| Display Name | OpenRouter ID | Provider | Notes |
|---|---|---|---|
| Hermes 3 405B | `nousresearch/hermes-3-llama-3.1-405b` | DeepInfra (free routing) | 131K ctx, ~18 tok/s |
| MiniMax Free | `minimax/...` | (current default) | via opencode-zen |

## Finding Model IDs on OpenRouter

1. Go to https://openrouter.ai/models
2. Search the model name
3. Click the model card — the ID is the slug in the URL and below the title
4. **Never append `:free`, `:fast`, `:beta` etc.** — these suffixes do not exist on OpenRouter

## Common Mistakes

- `nousresearch/hermes-3-llama-3.1-405b:free` → **404 Not Found** — remove `:free`
- Spaces in IDs → OpenRouter uses `/` as separator, not spaces
