defmodule ErgonSurfaceHudElixirWeb.PageController do
  use ErgonSurfaceHudElixirWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
