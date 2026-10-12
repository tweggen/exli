defmodule ExliWeb.GameApiSmokeTest do
  @moduledoc """
  Pins the path the game (Karawan's AutoSave) takes on a good day: log in
  for a token, store a save, read it back. It covers today's success
  answers only; how errors are answered is a separate change (KAR-423).
  """
  use ExliWeb.ConnCase, async: true

  import Exli.AccountsFixtures

  @game_title "silicondesert2"

  defp log_in(conn, email, password) do
    conn
    |> put_req_header("accept", "application/json")
    |> post(~p"/api/public/users/log_in", %{"user" => %{"email" => email, "password" => password}})
  end

  defp authed(token) do
    build_conn()
    |> put_req_header("accept", "application/json")
    |> put_req_header("x-nassau-token", token)
  end

  test "a known user logs in and gets a session token", %{conn: conn} do
    user = user_fixture()

    conn = log_in(conn, user.email, valid_user_password())

    assert %{"token" => token} = json_response(conn, 200)
    assert {:ok, raw} = Base.url_decode64(token)
    assert Exli.Accounts.get_user_by_session_token(raw).id == user.id
  end

  test "the token stores a save and reads it back", %{conn: conn} do
    user = user_fixture()
    %{"token" => token} = conn |> log_in(user.email, valid_user_password()) |> json_response(200)

    gamedata = ~s({"gameState": "smoke"})

    stored =
      post(authed(token), ~p"/api/auth/save_game", %{
        "game" => %{"title" => @game_title},
        "gamedata" => gamedata
      })

    assert stored.status == 200

    read = get(authed(token), ~p"/api/auth/save_game?gameTitle=#{@game_title}")

    assert %{"save" => %{"gamedata" => ^gamedata, "storedAt" => _}} = json_response(read, 200)
  end
end
