defmodule ExliWeb.PageController do
  use ExliWeb, :controller
  alias Exli.Accounts

  def sdsave(conn, _params) do
    user = conn.assigns.current_user
    game = Accounts.find_game("silicondesert2")
    #Accounts.find_game(conn.query_params["gameTitle"])
    latest_save = Accounts.latest_save(user, game)
    if nil == latest_save do
      conn
      |> send_resp(404, "Hi #{user.email}, I'm afraid you didn't save any game yet.")
    else
      conn
      |> put_status(200)
      |> json(%{
          :save => %{
            :gamedata => latest_save.gamedata, 
            :storedAt => latest_save.stored_at
          }
        }
      )
    end
  end

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def imprint(conn, _params) do
    render(conn, :imprint)
  end
end
