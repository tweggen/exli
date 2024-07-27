defmodule ExliWeb.RandomController do
  use ExliWeb, :controller

  def index(conn, _params) do
    user = conn.assigns.api_user
    conn
    |> send_resp(200, "Exli all for #{user.email}!")
  end
end