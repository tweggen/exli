#!/bin/bash
#
# Runs exli's whole test suite against a throwaway Postgres container,
# with the production Elixir/OTP in a container. Safe on a machine that
# already runs its own Postgres on 5432; the database container and its
# data are removed on exit, also on failure.
#
#   ./test-local.sh                          run all tests
#   ./test-local.sh test/exli_web/api_login_test.exs
#                                            arguments go to mix test
#   EXLI_LOCAL_DB_PORT=5499 ./test-local.sh  another database port
#
# Needs only docker.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/scripts/local-db.sh"
source "$ROOT/scripts/toolchain.sh"

toolchain_build
local_db_start

DB_ENV=(
    -e EXLI_TEST_DB_HOST="$LOCAL_DB_HOST"
    -e EXLI_TEST_DB_PORT="$LOCAL_DB_PORT"
    -e EXLI_TEST_DB_USER="$LOCAL_DB_USER"
    -e EXLI_TEST_DB_PASSWORD="$LOCAL_DB_PASSWORD"
)

run_mix test -- deps.get
run_mix test "${DB_ENV[@]}" -- ecto.create
run_mix test "${DB_ENV[@]}" -- ecto.migrate
run_mix test "${DB_ENV[@]}" -- test "$@"
