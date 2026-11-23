#!/bin/sh
# Railway start script for Vibe-Trading.
# - refuses to start without API_AUTH_KEY (the server would otherwise be open
#   to anyone who finds the URL and could spend your LLM key);
# - keeps all state on the Railway volume at /home/vibe/.vibe-trading;
# - trusts Railway's proxy headers so the browser's same-origin checks pass;
# - caps math-library threads for small (0.5 GB / 1 vCPU) plans;
# - drops from root to the unprivileged `vibe` user and execs the server, so a
#   crash or OOM exits non-zero and Railway's ON_FAILURE policy restarts it.
set -eu

if [ -z "${API_AUTH_KEY:-}" ]; then
  echo "[vibe-trading] API_AUTH_KEY is empty: refusing to start an unprotected server." >&2
  exit 1
fi

DATA_DIR=/home/vibe/.vibe-trading
mkdir -p "$DATA_DIR"
# A fresh Railway volume is owned by root; hand it to the app user once.
if [ "$(stat -c %U "$DATA_DIR")" != "vibe" ]; then
  chown -R vibe:vibe "$DATA_DIR"
fi
chmod 700 "$DATA_DIR"

export HOME=/home/vibe
export USER=vibe
export FORWARDED_ALLOW_IPS="${FORWARDED_ALLOW_IPS:-*}"
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-1}"
export OPENBLAS_NUM_THREADS="${OPENBLAS_NUM_THREADS:-1}"
export MKL_NUM_THREADS="${MKL_NUM_THREADS:-1}"
export NUMEXPR_MAX_THREADS="${NUMEXPR_MAX_THREADS:-1}"
export MPLCONFIGDIR=/tmp/matplotlib

PORT="${PORT:-8899}"
echo "[vibe-trading] starting on port $PORT (data in $DATA_DIR)"

# Keep CAP_SETUID/CAP_SETGID for `vibe` (as upstream's compose file does) so the
# backtest runner can drop generated code to `vibe-sandbox`. If the platform
# doesn't allow ambient capabilities, run without them (upstream falls back to
# its static code checks and logs a warning).
CAPS="--inh-caps=+setuid,+setgid --ambient-caps=+setuid,+setgid"
if ! setpriv --reuid=vibe --regid=vibe --init-groups $CAPS true 2>/dev/null; then
  echo "[vibe-trading] ambient capabilities unavailable; generated code runs as vibe" >&2
  CAPS=""
fi
exec setpriv --reuid=vibe --regid=vibe --init-groups $CAPS \
  vibe-trading serve --host 0.0.0.0 --port "$PORT"
