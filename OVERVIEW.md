# Deploy and Host Vibe-Trading on Railway

Vibe-Trading is an open-source AI trading research agent from the HKU Data Intelligence Lab (MIT licence). You ask questions in chat, and it pulls market data for stocks, crypto and futures, writes and backtests strategies, runs multi-agent research teams and produces reports. This template deploys its web app and HTTP API, version 0.1.19.

## About Hosting Vibe-Trading

This template runs one service: the Vibe-Trading server (FastAPI backend plus the built web UI) on Railway's `PORT`, with a health check on `/live`. It is built from our GitHub repo, which compiles the upstream v0.1.19 release commit with upstream's pinned base images, because upstream publishes no versioned image. Chats, backtest runs, reports, memory and Web UI settings live on a Railway volume at `/home/vibe/.vibe-trading`, so they survive redeploys. A generated `API_AUTH_KEY` locks the API: open the app, go to Settings, and paste that key once. You only bring an LLM API key. Analysis only: no broker keys are set.

## Common Use Cases

* Research a stock, ETF or crypto pair in plain language and get a written report with charts
* Write, backtest and compare trading strategies on free market data (Yahoo, OKX, AKShare and more)
* Run multi-agent "investment committee" or research-team workflows from the browser or over HTTP

## Dependencies for Vibe-Trading Hosting

* An LLM API key: OpenRouter by default, or OpenAI, DeepSeek, Anthropic, Gemini, Groq and other providers supported upstream
* A Railway volume for sessions, runs, memory and settings (created by the template)

### Deployment Dependencies

* Vibe-Trading on GitHub: https://github.com/HKUDS/Vibe-Trading
* Release v0.1.19: https://github.com/HKUDS/Vibe-Trading/releases/tag/v0.1.19
* Template source: https://github.com/aalfath/vibe-trading-railway-template
* OpenRouter keys: https://openrouter.ai/keys

### Implementation Details

**Services:** one service, `Vibe-Trading` (web UI and API, volume at `/home/vibe/.vibe-trading`). No database is needed: the app keeps its data in SQLite and files on the volume.

**Variables you set at deploy:**

* `OPENROUTER_API_KEY` (required): your OpenRouter key. Default model `deepseek/deepseek-v4-pro`; change `LANGCHAIN_MODEL_NAME` to any OpenRouter model id.
* To use another provider, set `LANGCHAIN_PROVIDER` (for example `openai`, `deepseek`, `anthropic`, `gemini`), its key variable (for example `OPENAI_API_KEY`) and `LANGCHAIN_MODEL_NAME`, in the deploy form or later in the service's Variables. Change these in Railway's Variables, not in the app's Settings page: Railway variables take precedence at every restart, so a provider, model or key changed only in Settings lasts until the next restart.

**After deploy:** open the service's Variables tab, copy `API_AUTH_KEY`, open the public URL, go to **Settings**, paste it under API key and save. Every API call, including from scripts, sends `Authorization: Bearer YOUR-API-AUTH-KEY`. The interactive API docs are at `https://YOUR-DOMAIN/docs`.

**Optional market-data keys** (add as service variables): `TUSHARE_TOKEN` for China A-shares, `FMP_API_KEY`, `FRED_API_KEY`. US/HK stocks (Yahoo) and crypto (OKX) work without keys.

**Left off on purpose:** shell tools for the agent (`VIBE_TRADING_ENABLE_SHELL_TOOLS`), live broker connections and the scheduler. Generated backtest code runs as a separate low-privilege user inside the container; no Docker-in-Docker is used.

**Resources:** idles at about 300 MB RAM and runs in 0.5 GB for chat and single backtests; give it 1 GB or more for multi-agent swarms and long backtests.

**Updates:** the service builds from our GitHub repo, so Railway shows an update notice when we move it to a new Vibe-Trading release. Read `CHANGELOG.md` in the repo before you apply it. Your data stays on the volume.

## Why Deploy Vibe-Trading on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Vibe-Trading on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
