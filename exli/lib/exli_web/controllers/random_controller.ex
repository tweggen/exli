defmodule ExliWeb.RandomController do
  use ExliWeb, :controller

  def index(conn, _params) do
    send_resp(conn, 200, "Exli all!")
  end
end