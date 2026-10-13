# exli
Unify reloaded.

The backend of Silicon Desert 2 (Karawan): player accounts, login for the
game and its online saves. The Phoenix app is in `exli/`.

**Production is deployed by Coolify from this repository's `main` branch
(Dockerfile mode). A push to `main` ships: work on a branch and merge through
a pull request.** Coolify has no health check configured, so the site answers
503 while a new image builds; check https://silicondesert.io after a merge.

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

Karawan's `nogame.modules.AutoSave` is the client. It quotes the `"error"`
text of a JSON answer on its login screen, and it depends on the statuses
below, so change them only together with the client (Karawan
`docs/main/docs/persistence/GAME_SERVER_API.md` has the client's side).
Tests: `test/exli_web/controllers/api_test.exs`.

| Call | Answer |
|------|--------|
| `POST /api/public/users/log_in` `{"user": {"email", "password"}}` | 200 `{"token": "<url-safe base64>"}` |
| same, wrong password or unknown eMail | **401** `{"error": "I'm sorry, I do not recognize you."}` |
| same, `user.email`/`user.password` missing or not strings | **400** `{"error": "expected user.email and user.password"}` |
| `GET /api/auth/save_game?gameTitle=…` | 200 `{"save": {"gamedata", "storedAt"}}` |
| same, no save yet | **404** `{"error": "no saved game yet"}` — the game starts a new game on exactly this answer |
| same, `gameTitle` missing or empty | **400** `{"error": "gameTitle is required"}` |
| `POST /api/auth/save_game` `{"game": {"title"}, "gamedata"}` | 200 text |
| same, title or gamedata missing or not strings | **400** `{"error": "expected game.title and gamedata"}` |
| same, the save is not stored | **500** `{"error": "could not store the save game"}` |
| any `/api/auth/*`: `x-nassau-token` missing, duplicated, not base64, unknown, or older than 60 days | **403** `{"error": "I'm sorry, I don't remember you. Please log in again."}` — the game drops its token and logs in again |

Any other exception renders through `ErrorJSON` in production
(`{"errors": {"detail": "<status text>"}}`).
