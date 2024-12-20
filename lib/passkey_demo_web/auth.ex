defmodule PasskeyDemoWeb.Auth do
  import Plug.Conn
  import Phoenix.Controller
  @behaviour Plug

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    case get_session(conn, "user") do
      nil -> redirect(conn, to: "/")
      _ -> conn
    end
  end
end
