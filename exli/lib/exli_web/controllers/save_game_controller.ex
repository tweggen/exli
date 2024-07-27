defmodule ExliWeb.SaveGameController do
  use ExliWeb, :controller
  alias Exli.Accounts

  def index(conn, _params) do
    [token64] = get_req_header(conn, "x-nassau-token")
    IO.inspect("Reading token header ")
    IO.inspect(token64)
    {_, token} = Base.url_decode64(token64, padding: false)
    user = Accounts.get_user_by_session_token(token)
    if nil==user do
      send_resp(conn, 403, "I'm sorry, I don't remember you. Would you mind to login again, obtaining a fresh token?")
    else
      send_resp(conn, 200, "Exli all for #{user.email}!")
    end
  end
end