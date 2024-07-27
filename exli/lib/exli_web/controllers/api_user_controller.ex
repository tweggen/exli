defmodule ExliWeb.ApiUserController do
  use ExliWeb, :controller

  alias Exli.Accounts
  alias ExliWeb.UserAuth

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      token = Accounts.generate_user_session_token(user)      
      conn
      |> json(%{token: Base.url_encode64(token)})
    else
      conn
      |> send_resp(200, "I'm sorry, I do not recognize you.")
    end
  end

  def delete(conn, _params) do
    conn
    |> UserAuth.log_out_user()
  end
end
