defmodule ExliWeb.ApiTest do
  @moduledoc """
  The game's API answers (KAR-423). Karawan's AutoSave depends on these
  statuses and quotes the JSON "error" texts on its login screen; see
  Karawan's docs/main/docs/persistence/ for the client side of the contract.
  """
  use ExliWeb.ConnCase, async: true

  import Ecto.Query
  import Exli.AccountsFixtures

  alias Exli.Accounts
  alias Exli.Repo

  @game_title "silicondesert2"
  @not_remembered "I'm sorry, I don't remember you. Please log in again."

  # The game sends no Accept header.
  defp log_in(params) do
    post(build_conn(), ~p"/api/public/users/log_in", params)
  end

  defp token_for(user) do
    Base.url_encode64(Accounts.generate_user_session_token(user))
  end

  defp authed(token) do
    put_req_header(build_conn(), "x-nassau-token", token)
  end

  defp null_games, do: Repo.aggregate(from(g in Accounts.Game, where: is_nil(g.name)), :count)

  describe "POST /api/public/users/log_in" do
    test "a known user gets a token" do
      user = user_fixture()

      conn = log_in(%{"user" => %{"email" => user.email, "password" => valid_user_password()}})

      assert %{"token" => token} = json_response(conn, 200)
      assert {:ok, _} = Base.url_decode64(token)
    end

    test "a wrong password answers 401 with the error" do
      user = user_fixture()

      conn = log_in(%{"user" => %{"email" => user.email, "password" => "not the password"}})

      assert json_response(conn, 401) == %{"error" => "I'm sorry, I do not recognize you."}
    end

    test "an unknown email answers the same 401" do
      conn = log_in(%{"user" => %{"email" => unique_user_email(), "password" => "whatever"}})

      assert json_response(conn, 401) == %{"error" => "I'm sorry, I do not recognize you."}
    end

    test "missing parameters answer 400" do
      for params <- [%{}, %{"user" => %{}}, %{"user" => %{"email" => "a@b.c"}}, %{"user" => "x"}] do
        conn = log_in(params)

        assert json_response(conn, 400) == %{"error" => "expected user.email and user.password"},
               "for #{inspect(params)}"
      end
    end

    test "non-string parameters answer 400" do
      conn = log_in(%{"user" => %{"email" => ["a@b.c"], "password" => %{"x" => "y"}}})

      assert json_response(conn, 400) == %{"error" => "expected user.email and user.password"}
    end
  end

  describe "the token plug" do
    test "a missing token answers 403" do
      conn = get(build_conn(), ~p"/api/auth/save_game?gameTitle=#{@game_title}")

      assert json_response(conn, 403) == %{"error" => @not_remembered}
    end

    test "a duplicated token header answers 403" do
      token = token_for(user_fixture())

      conn =
        build_conn()
        |> Map.update!(:req_headers, &([{"x-nassau-token", token}, {"x-nassau-token", token}] ++ &1))
        |> get(~p"/api/auth/save_game?gameTitle=#{@game_title}")

      assert json_response(conn, 403) == %{"error" => @not_remembered}
    end

    test "a token that is not base64 answers 403" do
      conn = get(authed("not*a*token"), ~p"/api/auth/save_game?gameTitle=#{@game_title}")

      assert json_response(conn, 403) == %{"error" => @not_remembered}
    end

    test "an unknown token answers 403" do
      conn =
        get(authed(Base.url_encode64(:crypto.strong_rand_bytes(32))), ~p"/api/auth/save_game?gameTitle=#{@game_title}")

      assert json_response(conn, 403) == %{"error" => @not_remembered}
    end

    test "an expired token answers 403" do
      user = user_fixture()
      token = token_for(user)

      Repo.update_all(
        from(t in Accounts.UserToken, where: t.user_id == ^user.id),
        set: [inserted_at: ~U[2020-01-01 00:00:00Z] |> DateTime.to_naive()]
      )

      conn = get(authed(token), ~p"/api/auth/save_game?gameTitle=#{@game_title}")

      assert json_response(conn, 403) == %{"error" => @not_remembered}
    end

    test "a token without padding is accepted" do
      token = user_fixture() |> token_for() |> String.trim_trailing("=")

      conn = get(authed(token), ~p"/api/auth/save_game?gameTitle=#{@game_title}")

      assert conn.status == 404
    end
  end

  describe "GET /api/auth/save_game" do
    test "the latest save is returned" do
      user = user_fixture()
      game = Accounts.find_game(@game_title)
      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      {:ok, _} =
        Accounts.add_save(user, %{gamedata: "{}", stored_at: now, game_id: game.id, user_id: user.id})

      conn = get(authed(token_for(user)), ~p"/api/auth/save_game?gameTitle=#{@game_title}")

      assert %{"save" => %{"gamedata" => "{}", "storedAt" => _}} = json_response(conn, 200)
    end

    test "no save yet answers 404 without the player's email" do
      user = user_fixture()

      conn = get(authed(token_for(user)), ~p"/api/auth/save_game?gameTitle=#{@game_title}")

      assert json_response(conn, 404) == %{"error" => "no saved game yet"}
      refute conn.resp_body =~ user.email
    end

    test "a missing gameTitle answers 400 and creates no game" do
      token = token_for(user_fixture())
      before = null_games()

      for path <- [~p"/api/auth/save_game", ~p"/api/auth/save_game?gameTitle="] do
        conn = get(authed(token), path)

        assert json_response(conn, 400) == %{"error" => "gameTitle is required"}
      end

      assert null_games() == before
    end
  end

  describe "POST /api/auth/save_game" do
    test "a save is stored" do
      user = user_fixture()

      conn =
        post(authed(token_for(user)), ~p"/api/auth/save_game", %{
          "game" => %{"title" => @game_title},
          "gamedata" => "{}"
        })

      assert conn.status == 200
      assert Accounts.latest_save(user, Accounts.find_game(@game_title)).gamedata == "{}"
    end

    test "bad parameters answer 400 and store nothing" do
      user = user_fixture()
      token = token_for(user)

      for params <- [
            %{},
            %{"gamedata" => "{}"},
            %{"game" => %{"title" => @game_title}},
            %{"game" => %{"title" => @game_title}, "gamedata" => %{"x" => "y"}},
            %{"game" => %{"title" => ""}, "gamedata" => "{}"}
          ] do
        conn = post(authed(token), ~p"/api/auth/save_game", params)

        assert json_response(conn, 400) == %{"error" => "expected game.title and gamedata"},
               "for #{inspect(params)}"
      end

      assert Repo.aggregate(from(s in Accounts.Save, where: s.user_id == ^user.id), :count) == 0
      assert null_games() == 0
    end
  end
end
