# Seeds the local harness database (dev-local.sh) with one known user the
# game can log in with. Never run this anywhere else: it refuses unless it
# runs under mix in the dev environment, against a database on this
# machine, with EXLI_LOCAL_SEED=1 set (dev-local.sh sets it).
#
#     EXLI_LOCAL_SEED=1 mix run priv/repo/seeds_local.exs

repo_config = Application.fetch_env!(:exli, Exli.Repo)
host = Keyword.get(repo_config, :hostname, "")

cond do
  not Code.ensure_loaded?(Mix) or Mix.env() != :dev ->
    raise "seeds_local.exs runs only under mix in the dev environment"

  System.get_env("EXLI_LOCAL_SEED") != "1" ->
    raise "seeds_local.exs needs EXLI_LOCAL_SEED=1; use dev-local.sh"

  host not in ["localhost", "127.0.0.1", "::1"] ->
    raise "seeds_local.exs refuses a database on #{inspect(host)}"

  true ->
    :ok
end

email = System.get_env("EXLI_LOCAL_USER_EMAIL", "player@local.test")
password = System.get_env("EXLI_LOCAL_USER_PASSWORD", "local password")

case Exli.Accounts.get_user_by_email(email) do
  nil ->
    {:ok, _user} = Exli.Accounts.register_user(%{email: email, password: password})
    IO.puts("Seeded local user #{email}")

  _user ->
    IO.puts("Local user #{email} already exists")
end
