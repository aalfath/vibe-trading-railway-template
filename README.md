[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/vibe-trading-1?utm_medium=integration&utm_source=button&utm_campaign=vibe-trading)

# Vibe-Trading on Railway

One-click Railway template for [Vibe-Trading](https://github.com/HKUDS/Vibe-Trading) (HKU Data Intelligence Lab, MIT), the AI trading research agent: research markets, write and backtest strategies, and get reports in chat.

**Version:** Vibe-Trading **v0.1.19**, built from the release commit `cb99dca528695ffe78429483a90399a89f61d614`. Upstream publishes no versioned container image (only a moving `edge` tag), so the `Dockerfile` here fetches that exact commit and runs upstream's own three-stage build, with upstream's pinned base images (`node:22-slim@sha256:6c74791e…`, `python:3.11-slim@sha256:e031123e…`) and hash-locked Python dependencies.

## What the template deploys

| Service | What it does | State |
|---|---|---|
| `Vibe-Trading` | FastAPI server plus the built web UI, on Railway's `PORT`; health check `/live` | Volume at `/home/vibe/.vibe-trading` (sessions, `sessions.db`, runs, reports, memory, uploads, Web UI settings) |

No database service is needed: Vibe-Trading stores everything in SQLite and files on the volume.

## Variables

| Variable | Default | Notes |
|---|---|---|
| `OPENROUTER_API_KEY` | *(you enter it)* | Required. Get one at https://openrouter.ai/keys |
| `LANGCHAIN_PROVIDER` | `openrouter` | Or `openai`, `deepseek`, `anthropic`, `gemini`, `groq`, … (then add that provider's key variable, e.g. `OPENAI_API_KEY`) |
| `LANGCHAIN_MODEL_NAME` | `deepseek/deepseek-v4-pro` | Upstream's default model; any model id of your provider |
| `API_AUTH_KEY` | `${{secret(40)}}` | Generated. Locks the API and web UI. Paste it once in the app's **Settings** |
| `PORT` | `8899` | Port the server listens on |

Optional market-data keys you can add later: `TUSHARE_TOKEN` (China A-shares), `FMP_API_KEY`, `FRED_API_KEY`. Yahoo (US/HK stocks) and OKX (crypto) need no key.

## After deploy

1. Copy `API_AUTH_KEY` from the service's **Variables** tab.
2. Open the public URL, go to **Settings**, paste the key under API key and save.
3. Ask a question, for example "Backtest a 50/200-day moving-average crossover on SPY since 2015".

Scripts call the same API with `Authorization: Bearer YOUR-API-AUTH-KEY`; the interactive docs are at `/docs`.

## Safety defaults

- The start script refuses to start when `API_AUTH_KEY` is empty, so the server is never open to the internet.
- Agent shell tools, live broker connections and the scheduler stay off (upstream defaults). Generated backtest code runs as the low-privilege `vibe-sandbox` user. No Docker-in-Docker or privileged mode.
- The server runs as the unprivileged `vibe` user; the start script only uses root to hand the fresh Railway volume to that user.
- A crash or out-of-memory kill exits non-zero, so Railway's on-failure restart policy brings it back.

## Resources

Idles at about 300 MB RAM. Chat and single backtests fit in 0.5 GB; give it 1 GB or more for multi-agent swarms and long backtests.

## Updates

Railway shows deployers an "update available" notice when this repo's `main` changes. Each update moves `VT_COMMIT` in the `Dockerfile` to a new upstream release and is described in [CHANGELOG.md](CHANGELOG.md), breaking changes first. Your data stays on the volume.

## Local test

```sh
docker build -t vibe-trading .
docker run --rm -p 8899:8899 -e API_AUTH_KEY=change-me -e OPENROUTER_API_KEY=sk-or-... \
  -e LANGCHAIN_PROVIDER=openrouter -e LANGCHAIN_MODEL_NAME=deepseek/deepseek-v4-pro \
  -v vibe-data:/home/vibe/.vibe-trading vibe-trading
```
