defmodule ExliWeb.PageController do
  use ExliWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def imprint(conn, _params) do
    render(conn, :imprint)
  end
end
