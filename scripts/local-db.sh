# Sourced by test-local.sh and dev-local.sh: starts a throwaway Postgres
# container and removes it again when the calling script exits.
#
# The container is started with --rm and no named volume, and bound to
# 127.0.0.1 only, so nothing outlives it and nothing else can reach it.
# It never touches a Postgres already running on 5432.
#
# Inputs (environment, all optional):
#   EXLI_LOCAL_DB_PORT   host port, default 5433
#   EXLI_LOCAL_DB_IMAGE  image, default postgres:16
# Outputs (exported): LOCAL_DB_HOST, LOCAL_DB_PORT, LOCAL_DB_USER,
#   LOCAL_DB_PASSWORD

LOCAL_DB_HOST=127.0.0.1
LOCAL_DB_PORT="${EXLI_LOCAL_DB_PORT:-5433}"
LOCAL_DB_USER=postgres
LOCAL_DB_PASSWORD=postgres
LOCAL_DB_IMAGE="${EXLI_LOCAL_DB_IMAGE:-postgres:16}"
LOCAL_DB_CONTAINER="exli-local-db-$$"
export LOCAL_DB_HOST LOCAL_DB_PORT LOCAL_DB_USER LOCAL_DB_PASSWORD

_local_db_stop() {
    # Mix containers first (toolchain.sh names them after this script's pid),
    # in case the docker client was killed before it could stop its own.
    local mix_containers
    mix_containers="$(docker ps -aq --filter "name=exli-local-mix-$$-" 2>/dev/null || true)"
    [ -n "$mix_containers" ] && docker rm -f -v $mix_containers >/dev/null 2>&1 || true
    docker rm -f -v "$LOCAL_DB_CONTAINER" >/dev/null 2>&1 || true
}

local_db_start() {
    if (exec 3<>"/dev/tcp/$LOCAL_DB_HOST/$LOCAL_DB_PORT") 2>/dev/null; then
        echo "Port $LOCAL_DB_PORT is in use; set EXLI_LOCAL_DB_PORT to a free port." >&2
        return 1
    fi

    trap _local_db_stop EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM

    echo "Starting throwaway Postgres $LOCAL_DB_CONTAINER on $LOCAL_DB_HOST:$LOCAL_DB_PORT ..."
    docker run -d --rm \
        --name "$LOCAL_DB_CONTAINER" \
        -p "$LOCAL_DB_HOST:$LOCAL_DB_PORT:5432" \
        -e POSTGRES_USER="$LOCAL_DB_USER" \
        -e POSTGRES_PASSWORD="$LOCAL_DB_PASSWORD" \
        "$LOCAL_DB_IMAGE" >/dev/null || return 1

    # pg_isready inside the container answers before the init scripts have
    # finished and the server restarted, so ask over TCP from the host side
    # as well, twice in a row.
    local ready=0
    for _ in $(seq 1 60); do
        if docker exec "$LOCAL_DB_CONTAINER" pg_isready -h 127.0.0.1 -U "$LOCAL_DB_USER" >/dev/null 2>&1; then
            ready=$((ready + 1))
            [ "$ready" -ge 2 ] && { echo "Postgres is ready."; return 0; }
        else
            ready=0
        fi
        sleep 1
    done
    echo "Postgres did not become ready in time." >&2
    docker logs "$LOCAL_DB_CONTAINER" >&2 || true
    return 1
}
