#!/usr/bin/env bash
# Bootstrap Superset on first start: run metadata migrations, create
# the admin user (idempotent), initialise roles/permissions, then
# launch the web server.
set -euo pipefail

echo "[superset-init] superset db upgrade ..."
superset db upgrade

echo "[superset-init] ensuring admin user '${ADMIN_USERNAME}' exists ..."
superset fab create-admin \
    --username "${ADMIN_USERNAME}" \
    --firstname Admin \
    --lastname User \
    --email "${ADMIN_EMAIL}" \
    --password "${ADMIN_PASSWORD}" || true

echo "[superset-init] superset init ..."
superset init

echo "[superset-init] starting gunicorn on :8088 ..."
exec gunicorn \
    --bind "0.0.0.0:8088" \
    --workers 2 \
    --timeout 120 \
    --worker-class gthread \
    --threads 4 \
    "superset.app:create_app()"
