defmodule ExliWeb.PageControllerTest do
  use ExliWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "silicon desert"
  end
end
