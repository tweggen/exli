defmodule ExliWeb.SaveGameController do
  use ExliWeb, :controller
  alias Exli.Accounts


  def create(conn, %{"game" => %{"title" => game_title}, "gamedata" => gamedata} = _params) do
    user = conn.assigns.api_user
    game = Accounts.find_game(game_title)
    IO.inspect(game)
    #{:ok, game} = res
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    Accounts.add_save(user, %{
      :gamedata => gamedata,
      :stored_at => now,
      :game_id => game.id,
      :user_id => user.id
    })
    conn
    |> send_resp(200, "Hi #{user.email}, I stored your exli.")
  end


  def index(conn, params) do
    user = conn.assigns.api_user
    game = Accounts.find_game(conn.query_params["gameTitle"])
    save = Accounts.latest_save(user, game)
    if nil == save do
      conn
      |> send_resp(404, "Hi #{user.email}, I'm afraid you didn't save any game yet.")
    else
      conn
      |> put_status(200)
      |> json(%{:save => %{:gamedata => save.gamedata, :storedAt => save.stored_at}})
    end
  end
end