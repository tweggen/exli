defmodule ExliWeb.SaveGameController do
  use ExliWeb, :controller
  alias Exli.Accounts

  # The game reads a 404 from index as "no saved game yet" and starts a new
  # one; every other failure is reported to the player. Keep that status.

  def create(conn, %{"game" => %{"title" => game_title}, "gamedata" => gamedata})
      when is_binary(game_title) and game_title != "" and is_binary(gamedata) do
    user = conn.assigns.api_user
    game = Accounts.find_game(game_title)
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    case Accounts.add_save(user, %{
           :gamedata => gamedata,
           :stored_at => now,
           :game_id => game.id,
           :user_id => user.id
         }) do
      {:ok, _save} ->
        conn
        |> send_resp(200, "Hi #{user.email}, I stored your exli.")

      {:error, _changeset} ->
        conn
        |> put_status(500)
        |> json(%{error: "could not store the save game"})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{error: "expected game.title and gamedata"})
  end

  def index(conn, %{"gameTitle" => game_title}) when is_binary(game_title) and game_title != "" do
    user = conn.assigns.api_user
    game = Accounts.find_game(game_title)
    save = Accounts.latest_save(user, game)

    if nil == save do
      conn
      |> put_status(404)
      |> json(%{error: "no saved game yet"})
    else
      conn
      |> put_status(200)
      |> json(%{:save => %{:gamedata => save.gamedata, :storedAt => save.stored_at}})
    end
  end

  def index(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{error: "gameTitle is required"})
  end
end
