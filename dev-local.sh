#!/bin/bash
#
# Runs exli on http://localhost:4100 against a throwaway Postgres
# container with one seeded user, so a local game build can log in
# without touching production. Stop it with Ctrl-C; the database and
# everything in it go away with it.
#
#   ./dev-local.sh
#   EXLI_LOCAL_USER_EMAIL=me@local.test EXLI_LOCAL_USER_PASSWORD='...' ./dev-local.sh
#   EXLI_LOCAL_DB_PORT=5499 ./dev-local.sh
#
# Point the game at it with a local, never committed edit, see
# Karawan's docs/testing/docs/LOGIN_SERVER_HARNESS.md.
#
# Needs only docker. Port 4100 must be free.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/scripts/local-db.sh"
source "$ROOT/scripts/toolchain.sh"

if (exec 3<>/dev/tcp/127.0.0.1/4100) 2>/dev/null; then
    echo "Port 4100 is in use; stop whatever listens there first." >&2
    exit 1
fi

export EXLI_LOCAL_USER_EMAIL="${EXLI_LOCAL_USER_EMAIL:-player@local.test}"
export EXLI_LOCAL_USER_PASSWORD="${EXLI_LOCAL_USER_PASSWORD:-local password}"

toolchain_build
local_db_start

DEV_ENV=(
    -e EXLI_DEV_DB_HOST="$LOCAL_DB_HOST"
    -e EXLI_DEV_DB_PORT="$LOCAL_DB_PORT"
    -e EXLI_DEV_DB_USER="$LOCAL_DB_USER"
    -e EXLI_DEV_DB_PASSWORD="$LOCAL_DB_PASSWORD"
    -e EXLI_DEV_DB_NAME=exli_local
    -e EXLI_LOCAL_SEED=1
    -e EXLI_LOCAL_USER_EMAIL
    -e EXLI_LOCAL_USER_PASSWORD
)

run_mix dev -- deps.get
run_mix dev "${DEV_ENV[@]}" -- ecto.create
run_mix dev "${DEV_ENV[@]}" -- ecto.migrate
run_mix dev "${DEV_ENV[@]}" -- run priv/repo/seeds_local.exs

cat <<INFO

================================================================
 exli runs on http://localhost:4100   (Ctrl-C stops it)
 log in with
   eMail:    $EXLI_LOCAL_USER_EMAIL
   password: $EXLI_LOCAL_USER_PASSWORD
================================================================

INFO

run_mix dev "${DEV_ENV[@]}" -- phx.server
