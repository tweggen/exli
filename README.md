# exli
Unify reloaded.

The backend of Silicon Desert 2 (Karawan): player accounts, login for the
game and its online saves. The Phoenix app is in `exli/`.

**Production is deployed by Coolify from this repository's `main` branch
(Dockerfile mode). A push to `main` ships: work on a branch and merge through
a pull request.** `exli/fly.toml` and `exli/start-server.sh` are from an
earlier Fly.io setup and are not used.

## Testing locally

Both scripts need only Docker. They start a throwaway Postgres 16 on
`127.0.0.1:5433` (set `EXLI_LOCAL_DB_PORT` for another port) and remove it on
every exit, so they are safe next to a Postgres you already run on 5432.
mix runs in a container with production's Elixir 1.16.1 / OTP 26.2.2
(`scripts/Dockerfile.toolchain`); its deps, builds and Hex cache go to
`.local-cache/`.

```bash
./test-local.sh                       # exli's whole test suite
./test-local.sh test/exli_web/api     # arguments go to mix test
./dev-local.sh                        # exli on http://localhost:4100 with a seeded user
```

`dev-local.sh` seeds `player@local.test` / `local password`
(`EXLI_LOCAL_USER_EMAIL`, `EXLI_LOCAL_USER_PASSWORD`) through
`exli/priv/repo/seeds_local.exs`, which refuses to run anywhere but a local dev
database. Ctrl-C stops the server and discards the database.

How to point the game at it, and which login cases to try:
`docs/testing/docs/LOGIN_SERVER_HARNESS.md` in the Karawan repository.

A run may rewrite the heroicons entry in `exli/mix.lock` (dropping
`depth: 1`; same commit). Do not commit that.

`start-dockers.sh` starts a persistent Postgres on 5432 for a plain
`mix phx.server` setup; it conflicts with a system Postgres on that port.

## The game's API

| Call | Answer today |
|------|--------------|
| `POST /api/public/users/log_in` `{"user": {"email", "password"}}` | 200 `{"token": …}`; a wrong login is also **200**, plain text "I'm sorry, I do not recognize you." |
| `GET /api/auth/save_game?gameTitle=…` (header `x-nassau-token`) | 200 `{"save": {"gamedata", "storedAt"}}`; 404 text when there is no save |
| `POST /api/auth/save_game` `{"game": {"title"}, "gamedata"}` | 200 text |
| any `/api/auth/*` with an unknown token | 403 text; a token that is not base64 gives 500 |

These error answers are being reworked (Karawan KAR-423,
`docs/main/plans/proposed/LOGIN-SERVER-ERRORS.md`).
