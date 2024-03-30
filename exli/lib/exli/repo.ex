defmodule Exli.Repo do
  use Ecto.Repo,
    otp_app: :exli,
    adapter: Ecto.Adapters.Postgres
end
