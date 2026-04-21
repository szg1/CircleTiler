#!/usr/bin/env bash
set -Eeuo pipefail

# Usage: ./deploy.sh <service-name> [host]
APP="${1:-}"
HOST="${2:-root@cyberhorizon.hu}"

if [[ -z "${APP}" ]]; then
  echo "Usage: $0 <service-name> [host]" >&2
  exit 1
fi

echo "Deploying '${APP}' to ${HOST}"

# Paths & service user
REMOTE_BASE="/opt"
REMOTE_DIR="${REMOTE_BASE}/${APP}"
REMOTE_APP="${REMOTE_DIR}/app"
APPUSER="svc-${APP}"
APPGROUP="${APPUSER}"

# ---- Pre-flight checks -------------------------------------------------------
[[ -d "app" ]] || { echo "Missing app/ directory"; exit 1; }
[[ -f "run.sh" ]] || { echo "Missing run.sh"; exit 1; }
[[ -f "requirements.txt" ]] || { echo "Missing requirements.txt"; exit 1; }

# ---- Ensure user & directories on remote ------------------------------------
echo "Preparing remote user and directories..."
ssh -o StrictHostKeyChecking=accept-new "${HOST}" bash -lc "set -Eeuo pipefail
if ! id -u '${APPUSER}' >/dev/null 2>&1; then
  useradd --system --create-home --shell /usr/sbin/nologin '${APPUSER}'
fi
mkdir -p '${REMOTE_APP}'
chown -R '${APPUSER}:${APPGROUP}' '${REMOTE_DIR}'
"

# ---- Sync app/ (code, templates, static), exclude caches --------------------
echo "Syncing app/ ..."
rsync -az --delete \
  --exclude='__pycache__' \
  --exclude='*.pyc' \
  app/ "${HOST}:${REMOTE_APP}/"

# ---- Copy ancillary files ----------------------------------------------------
echo "Copying requirements.txt and run.sh ..."
scp requirements.txt "${HOST}:${REMOTE_DIR}/requirements.txt"
scp run.sh "${HOST}:${REMOTE_DIR}/run.sh"
[[ -f README.md ]] && scp README.md "${HOST}:${REMOTE_DIR}/README.md"

# ---- Permissions -------------------------------------------------------------
ssh "${HOST}" bash -lc "set -Eeuo pipefail
chown -R '${APPUSER}:${APPGROUP}' '${REMOTE_DIR}'
chmod +x '${REMOTE_DIR}/run.sh'
"

# ---- Stop/start service ------------------------------------------------------
echo "Restarting '${APP}' service..."
ssh "${HOST}" bash -lc "set -Eeuo pipefail
sudo /bin/systemctl stop '${APP}' || true
sudo /bin/systemctl start '${APP}'
sudo /bin/systemctl --no-pager --full status '${APP}' || true
"

echo "Deploy complete."
