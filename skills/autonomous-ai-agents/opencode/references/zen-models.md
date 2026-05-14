# OpenCode Zen — Model Catalog & Pricing

Source: https://opencode.ai/docs/usage/zen (fetched 2026-05-09)

## Overview

OpenCode Zen is a curated AI gateway by the OpenCode team. They test model/provider combinations and benchmark them for coding-agent performance. Currently in beta.

- Sign in at https://opencode.ai/zen, add billing, get API key
- Connect via `/connect` in the TUI or set `provider: opencode` in config
- Model IDs in config use `opencode/<model-id>` (e.g. `opencode/gpt-5.5`)

## Endpoint Pattern

| Provider | Endpoint |
|----------|----------|
| OpenAI-compatible | `https://opencode.ai/zen/v1/chat/completions` |
| Anthropic-compatible | `https://opencode.ai/zen/v1/messages` |
| Google-compatible | `https://opencode.ai/zen/v1/models/{model-id}` |
| Responses API | `https://opencode.ai/zen/v1/responses` |

## Free Models (limited time)

All free — input, output, and cached read.

| Model ID | Notes |
|----------|-------|
| `big-pickle` | Stealth model. Data may be used for training during free period. |
| `minimax-m2.5-free` | Free version of MiniMax M2.5 ($0.30/$1.20 paid) |
| `ling-2.6-flash-free` | Inclusion AI Ling 2.6 (~1T MoE). Fast variant. |
| `hy3-preview-free` | Tencent Hy3. Preview/early release. |
| `nemotron-3-super-free` | NVIDIA Nemotron 3 Super 120B. Strong reasoning. |

## Paid Models (prices per 1M tokens)

| Model | Input | Output | Cached Read | Cached Write |
|-------|-------|--------|-------------|--------------|
| MiniMax M2.7 | $0.30 | $1.20 | $0.06 | $0.375 |
| MiniMax M2.5 | $0.30 | $1.20 | $0.06 | $0.375 |
| GLM 5.1 | $1.40 | $4.40 | $0.26 | - |
| GLM 5 | $1.00 | $3.20 | $0.20 | - |
| Kimi K2.5 | $0.60 | $3.00 | $0.10 | - |
| Kimi K2.6 | $0.95 | $4.00 | $0.16 | - |
| Qwen3.6 Plus | $0.50 | $3.00 | $0.05 | $0.625 |
| Qwen3.5 Plus | $0.20 | $1.20 | $0.02 | $0.25 |
| Claude Opus 4.7 | $5.00 | $25.00 | $0.50 | $6.25 |
| Claude Opus 4.6 | $5.00 | $25.00 | $0.50 | $6.25 |
| Claude Opus 4.5 | $5.00 | $25.00 | $0.50 | $6.25 |
| Claude Opus 4.1 | $15.00 | $75.00 | $1.50 | $18.75 |
| Claude Sonnet 4.6 | $3.00 | $15.00 | $0.30 | $3.75 |
| Claude Sonnet 4.5 (<=200K) | $3.00 | $15.00 | $0.30 | $3.75 |
| Claude Sonnet 4.5 (>200K) | $6.00 | $22.50 | $0.60 | $7.50 |
| Claude Sonnet 4 (<=200K) | $3.00 | $15.00 | $0.30 | $3.75 |
| Claude Sonnet 4 (>200K) | $6.00 | $22.50 | $0.60 | $7.50 |
| Claude Haiku 4.5 | $1.00 | $5.00 | $0.10 | $1.25 |
| Gemini 3.1 Pro (<=200K) | $2.00 | $12.00 | $0.20 | - |
| Gemini 3.1 Pro (>200K) | $4.00 | $18.00 | $0.40 | - |
| Gemini 3 Flash | $0.50 | $3.00 | $0.05 | - |
| GPT 5.5 (<=272K) | $5.00 | $30.00 | $0.50 | - |
| GPT 5.5 (>272K) | $10.00 | $45.00 | $1.00 | - |
| GPT 5.5 Pro | $30.00 | $180.00 | $30.00 | - |
| GPT 5.4 (<=272K) | $2.50 | $15.00 | $0.25 | - |
| GPT 5.4 (>272K) | $5.00 | $22.50 | $0.50 | - |
| GPT 5.4 Pro | $30.00 | $180.00 | $30.00 | - |
| GPT 5.4 Mini | $0.75 | $4.50 | $0.075 | - |
| GPT 5.4 Nano | $0.20 | $1.25 | $0.02 | - |
| GPT 5.3 Codex Spark | $1.75 | $14.00 | $0.175 | - |
| GPT 5.3 Codex | $1.75 | $14.00 | $0.175 | - |
| GPT 5.2 | $1.75 | $14.00 | $0.175 | - |
| GPT 5.2 Codex | $1.75 | $14.00 | $0.175 | - |
| GPT 5.1 | $1.07 | $8.50 | $0.107 | - |
| GPT 5.1 Codex | $1.07 | $8.50 | $0.107 | - |
| GPT 5.1 Codex Max | $1.25 | $10.00 | $0.125 | - |
| GPT 5.1 Codex Mini | $0.25 | $2.00 | $0.025 | - |
| GPT 5 | $1.07 | $8.50 | $0.107 | - |
| GPT 5 Codex | $1.07 | $8.50 | $0.107 | - |
| GPT 5 Nano | $0.05 | $0.40 | $0.005 | - |

## Auto-Reload & Limits

- Auto-reload triggers at $5 balance, reloads $20 (configurable)
- Monthly usage limits available per workspace and per team member
- Credit card fee: 4.4% + $0.30/transaction (passed at cost, not a markup)

## Privacy Notes

Most models: zero-retention policy, no training on your data.
Free models (Big Pickle, MiniMax M2.5 Free, Ling 2.6 Flash Free, Hy3 Preview Free, Nemotron 3 Super Free): data may be used for model improvement during free period.

## Fetching Current Model List (API)

```bash
curl https://opencode.ai/zen/v1/models
```

Returns an OpenAI-compatible list endpoint with model IDs.

## See Also

- OpenCode Zen docs: https://opencode.ai/docs/usage/zen
- OpenCode Zen login: https://opencode.ai/zen
