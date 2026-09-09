#!/usr/bin/env bash
# Run the TaskTeddy backend test suite inside the running backend container,
# against an isolated `<db>_test` database (never the real data).
#
# Usage:
#   ./run_tests.sh              # run everything
#   ./run_tests.sh -m unit      # only the fast unit tests
#   ./run_tests.sh -k promo     # only tests matching "promo"
#   ./run_tests.sh --cov        # with a coverage report
set -euo pipefail

cd "$(dirname "$0")/.."   # repo root (where docker-compose lives)

SVC=backend
APP_DIR=/app

echo "▶ Copying tests into the container…"
CID="$(docker compose ps -q "$SVC")"
if [ -z "$CID" ]; then
  echo "✖ backend container is not running. Start it with: docker compose up -d backend"
  exit 1
fi
# Remove any prior copy first — `docker cp` into an existing dir would NEST it.
# Files land root-owned, so remove as root (the app runs as a non-root user).
docker exec -u root "$CID" rm -rf "$APP_DIR/tests" "$APP_DIR/pytest.ini"
docker cp backend/tests "$CID:$APP_DIR/tests"
docker cp backend/pytest.ini "$CID:$APP_DIR/pytest.ini"

echo "▶ Ensuring pytest is installed…"
docker compose exec -T "$SVC" pip install -q pytest==8.3.4 pytest-cov==6.0.0 >/dev/null

echo "▶ Running tests…"
COV_ARGS=""
if [ "${1:-}" = "--cov" ]; then
  COV_ARGS="--cov=routes --cov=utils --cov-report=term-missing"
  shift || true
fi
docker compose exec -T -w "$APP_DIR" "$SVC" \
  python -m pytest -p no:cacheprovider -W ignore::DeprecationWarning ${COV_ARGS} "$@"
