defmodule ExliWeb.Controllers.ApiUserPlug do
  import Plug.Conn

  alias Exli.Accounts

  def init(default), do: default

  def call(%Plug.Conn{} = conn, _default) do
    try do
      [token64] = get_req_header(conn, "x-nassau-token")
      IO.inspect("Reading token header ")
      IO.inspect(token64)
      {_, token} = Base.url_decode64(token64, padding: false)
      user = Accounts.get_user_by_session_token(token)
      if user != nil do
        IO.inspect("Have user")
        conn 
        |> assign(:api_user, user)
      else
        IO.inspect("No user")
        raise "user not found."
      end
    rescue
      e in RuntimeError -> 
        conn
        |> send_resp(403, "I'm sorry, I don't remember you. Would you mind to login again, obtaining a fresh token?")
        |> halt()
    end
  end

end