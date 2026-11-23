# Vibe-Trading on Railway: HKUDS/Vibe-Trading v0.1.19, built from the release commit.
#
# Upstream publishes no versioned image (ghcr.io/hkuds/vibe-trading only has an
# `edge` tag), so this Dockerfile builds upstream's own three-stage Dockerfile
# from the v0.1.19 release commit, fetched by its full SHA. Base images are the
# exact digests upstream pins in that release.
#
# To update: change VT_COMMIT to the next release commit and add a CHANGELOG entry.

# ---------------------------------------------------------------------------
# Stage 0: source at the pinned release commit (v0.1.19)
# ---------------------------------------------------------------------------
FROM buildpack-deps:bookworm-scm@sha256:5bac6b3020afcf0358de87990605d5dc4c3f060629381912266b9b9278375af3 AS source
ARG VT_COMMIT=cb99dca528695ffe78429483a90399a89f61d614
WORKDIR /src
RUN git init -q . \
    && git remote add origin https://github.com/HKUDS/Vibe-Trading.git \
    && git fetch -q --depth 1 origin "$VT_COMMIT" \
    && git checkout -q FETCH_HEAD \
    && test "$(git rev-parse HEAD)" = "$VT_COMMIT" \
    && rm -rf .git .github agent/tests assets docs desktop wiki zimaos pixel-office \
              frontend/node_modules frontend/dist README_*.md CHANGELOG.md

# ---------------------------------------------------------------------------
# Stage 1: frontend (upstream's pin)
# ---------------------------------------------------------------------------
FROM node:22-slim@sha256:6c74791e557ce11fc957704f6d4fe134a7bc8d6f5ca4403205b2966bd488f6b3 AS frontend-build
WORKDIR /app/frontend
COPY --from=source /src/frontend/package.json /src/frontend/package-lock.json ./
RUN npm ci --ignore-scripts --no-audit --no-fund
COPY --from=source /src/frontend/ ./
RUN npm run build

# ---------------------------------------------------------------------------
# Stage 2: Python venv from upstream's hash-pinned locks (upstream's pin)
# ---------------------------------------------------------------------------
FROM python:3.11-slim@sha256:e031123e3d85762b141ad1cbc56452ba69c6e722ebf2f042cc0dc86c47c0d8b3 AS builder
RUN apt-get update && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*
ENV VIRTUAL_ENV=/opt/venv
RUN python -m venv "$VIRTUAL_ENV"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
WORKDIR /app
COPY --from=source /src/agent/requirements.txt agent/requirements.txt
COPY --from=source /src/requirements-lock.txt requirements-lock.txt
RUN pip install --no-cache-dir --require-hashes -r requirements-lock.txt
COPY --from=source /src/requirements-channels-lock.txt requirements-channels-lock.txt
RUN pip install --no-cache-dir --require-hashes -r requirements-channels-lock.txt
COPY --from=source /src/pyproject.toml /src/LICENSE /src/README.md ./
COPY --from=source /src/agent/ agent/
RUN pip install --no-cache-dir --no-deps -e .

# ---------------------------------------------------------------------------
# Stage 3: runtime (upstream's pin and runtime packages)
# ---------------------------------------------------------------------------
FROM python:3.11-slim@sha256:e031123e3d85762b141ad1cbc56452ba69c6e722ebf2f042cc0dc86c47c0d8b3 AS runtime
LABEL org.opencontainers.image.title="Vibe-Trading (Railway template)" \
      org.opencontainers.image.version="0.1.19" \
      org.opencontainers.image.source="https://github.com/aalfath/vibe-trading-railway-template" \
      org.opencontainers.image.licenses="MIT"
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpango-1.0-0 libpangoft2-1.0-0 libharfbuzz0b libfontconfig1 \
    libgdk-pixbuf-2.0-0 libcairo2 fonts-dejavu-core fonts-noto-core fonts-noto-cjk \
    && rm -rf /var/lib/apt/lists/*
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
COPY --from=builder /opt/venv /opt/venv
COPY --from=source /src/pyproject.toml /src/LICENSE /src/README.md ./
COPY --from=source /src/agent/ agent/
COPY --from=frontend-build /app/frontend/dist frontend/dist
# Same users as upstream: `vibe` runs the server, `vibe-sandbox` runs
# LLM-generated backtest code with fewer privileges.
RUN useradd --create-home --shell /usr/sbin/nologin vibe \
    && useradd --system --no-create-home --shell /usr/sbin/nologin --uid 10001 vibe-sandbox \
    && mkdir -p agent/runs agent/sessions agent/uploads agent/.swarm/runs /home/vibe/.vibe-trading \
    && chown -R vibe:vibe /app /home/vibe/.vibe-trading
COPY start.sh /usr/local/bin/vibe-trading-start
RUN chmod 755 /usr/local/bin/vibe-trading-start
EXPOSE 8899
# Starts as root only to fix the Railway volume's ownership, then drops to `vibe`.
ENTRYPOINT ["/usr/local/bin/vibe-trading-start"]
