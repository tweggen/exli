# Sourced by test-local.sh and dev-local.sh: runs mix in a container with
# the production Elixir/OTP (see Dockerfile.toolchain) instead of whatever
# the host has installed.
#
# The container runs as the calling user with host networking, so it
# reaches the throwaway database on 127.0.0.1 and serves on the host's
# ports directly (Linux). Its deps, build output and Hex cache live in
# .local-cache/ at the repo root, apart from a host build's deps/ and _build/.

TOOLCHAIN_IMAGE=exli-local-toolchain:1.16.1-otp-26.2.2
_mix_run_count=0

toolchain_build() {
    docker build -q -t "$TOOLCHAIN_IMAGE" -f "$ROOT/scripts/Dockerfile.toolchain" "$ROOT/scripts" >/dev/null
}

# run_mix <MIX_ENV> [docker run options ...] -- <mix args ...>
run_mix() {
    local mix_env="$1"; shift
    local opts=()
    while [ "$#" -gt 0 ] && [ "$1" != "--" ]; do opts+=("$1"); shift; done
    shift
    local cache="$ROOT/.local-cache"
    mkdir -p "$cache/home"
    _mix_run_count=$((_mix_run_count + 1))
    docker run --rm --init \
        --name "exli-local-mix-$$-$_mix_run_count" \
        --network host \
        --user "$(id -u):$(id -g)" \
        -v "$ROOT:/src" \
        -w /src/exli \
        -e HOME=/src/.local-cache/home \
        -e MIX_HOME=/src/.local-cache/mix \
        -e HEX_HOME=/src/.local-cache/hex \
        -e MIX_DEPS_PATH=/src/.local-cache/deps \
        -e MIX_BUILD_PATH="/src/.local-cache/_build/$mix_env" \
        -e MIX_ENV="$mix_env" \
        "${opts[@]}" \
        "$TOOLCHAIN_IMAGE" \
        sh -c 'mix local.hex --force --if-missing >/dev/null && mix local.rebar --force --if-missing >/dev/null && exec mix "$@"' mix "$@"
}
