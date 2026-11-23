# Changelog

## v0.1.19 (2026-11-23)

First release of this template.

- Vibe-Trading v0.1.19 (upstream release 2026-11-05, commit `cb99dca5`), built from source with upstream's pinned base images, because upstream publishes no versioned image.
- One service with a volume at `/home/vibe/.vibe-trading`, health check `/live`, generated `API_AUTH_KEY`, OpenRouter as the default LLM provider.
