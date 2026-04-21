#!/usr/bin/env bash
set -Eeuo pipefail

APP="${1:-}"
if [[ -z "$APP" ]]; then
  echo "Usage: $0 <service-name>" >&2
  exit 1
fi

BASE="/opt/${APP}"
VENV="${BASE}/.venv"
REQS="${BASE}/requirements.txt"

log(){ printf '[%s] %s\n' "$APP" "$*"; }
fail(){ printf '[%s] ERROR: %s\n' "$APP" "$*" >&2; exit 1; }

log "running as: $(id -u -n) (uid $(id -u))"

[[ -x "$BASE" ]] || fail "Cannot traverse $BASE (missing +x on directory)"
[[ -r "$BASE" ]] || fail "Cannot read $BASE"

# Create venv if missing
if [[ ! -d "$VENV" ]]; then
  log "creating venv at $VENV"
  python3 -m venv "$VENV" || fail "venv creation failed at $VENV"
fi

# Activate venv
# shellcheck disable=SC1090
source "$VENV/bin/activate" || fail "cannot activate venv at $VENV"
log "venv activated: $(python --version)"

# Use venv's pip explicitly
export PIP_DISABLE_PIP_VERSION_CHECK=1
python -m pip install --upgrade pip setuptools wheel || fail "pip tooling upgrade failed"

if [[ -f "$REQS" ]]; then
  log "installing requirements from $REQS"
  python -m pip install --no-input --no-cache-dir -r "$REQS" || fail "pip install failed"
else
  log "WARNING: $REQS not found; continuing"
fi

cd "$BASE" || fail "cannot cd to $BASE"

# Configurable port & workers (can also set in systemd Environment=)
PORT="${PORT:-8445}"
WORKERS="${WORKERS:-4}"

log "starting uvicorn on 0.0.0.0:${PORT} with ${WORKERS} workers"
exec python -m uvicorn app.main:app --host 0.0.0.0 --port "$PORT" --workers "$WORKERS"
