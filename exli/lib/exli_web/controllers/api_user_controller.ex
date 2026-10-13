defmodule ExliWeb.ApiUserController do
  use ExliWeb, :controller

  alias Exli.Accounts
  alias ExliWeb.UserAuth

  # The game (Karawan's AutoSave) is this API's client: it quotes the
  # "error" text of a JSON answer on its login screen.
  def create(conn, %{"user" => %{"email" => email, "password" => password}})
      when is_binary(email) and is_binary(password) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      token = Accounts.generate_user_session_token(user)

      conn
      |> json(%{token: Base.url_encode64(token)})
    else
      conn
      |> put_status(401)
      |> json(%{error: "I'm sorry, I do not recognize you."})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{error: "expected user.email and user.password"})
  end

  def delete(conn, _params) do
    conn
    |> UserAuth.log_out_user()
  end
end
