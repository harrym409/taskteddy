#!/usr/bin/env sh
set -e

# Apply database migrations before serving. In production the schema is owned by
# Alembic (server.py no longer runs create_all). This is idempotent: re-running
# with no pending migrations is a no-op.
if [ "${RUN_MIGRATIONS:-true}" = "true" ]; then
  echo "[entrypoint] Running database migrations (alembic upgrade head)..."
  alembic upgrade head
fi

# Serve with gunicorn managing uvicorn workers. Tune worker count with
# WEB_CONCURRENCY (default 4). All workers share one stable JWT_SECRET.
echo "[entrypoint] Starting gunicorn with ${WEB_CONCURRENCY:-4} uvicorn worker(s)..."
exec gunicorn server:app \
  --worker-class uvicorn.workers.UvicornWorker \
  --workers "${WEB_CONCURRENCY:-4}" \
  --bind "0.0.0.0:${PORT:-8000}" \
  --access-logfile - \
  --error-logfile - \
  --timeout 60
