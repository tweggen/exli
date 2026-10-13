defmodule ExliWeb.Controllers.ApiUserPlug do
  @moduledoc """
  Authenticates the game's API calls by the `x-nassau-token` header: the
  url-safe base64 of a session token from `ApiUserController.create`.

  Any failure (header missing, duplicated or not base64, token unknown or
  expired) answers 403 with a JSON "error"; the game then drops its stored
  token and logs in again.
  """
  import Plug.Conn

  alias Exli.Accounts

  def init(default), do: default

  def call(%Plug.Conn{} = conn, _default) do
    with [token64] <- get_req_header(conn, "x-nassau-token"),
         {:ok, token} <- Base.url_decode64(token64, padding: false),
         %Accounts.User{} = user <- Accounts.get_user_by_session_token(token) do
      assign(conn, :api_user, user)
    else
      _ ->
        conn
        |> put_status(403)
        |> Phoenix.Controller.json(%{
          error: "I'm sorry, I don't remember you. Please log in again."
        })
        |> halt()
    end
  end
end
