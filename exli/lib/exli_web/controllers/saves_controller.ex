defmodule ExliWeb.SavesController do
  use ExliWeb, :controller
  alias Exli.Accounts


  def index(conn, params) do
    user = conn.assigns.api_user
    game = Accounts.find_game(conn.query_params["gameTitle"])
    saves = Accounts.all_saves(user, game)
    if nil == saves do
      conn
      |> send_resp(404, "Hi #{user.email}, I'm afraid you didn't save any game yet.")
    else
      conn
      |> put_status(200)
      |> json(
          Enum.map(saves,
            fn save -> %{:save => %{:gamedata => save.gamedata, :storedAt => save.stored_at}} end
          )
        )
    end
  end
end