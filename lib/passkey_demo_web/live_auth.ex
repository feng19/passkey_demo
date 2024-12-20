defmodule PasskeyDemoWeb.LiveAuth do
  use Phoenix.VerifiedRoutes, endpoint: PasskeyDemoWeb.Endpoint, router: PasskeyDemoWeb.Router
  import Phoenix.LiveView

  def on_mount(_opts, _params, session, socket) do
    if session["user"] do
      {:halt, redirect(socket, to: ~p"/me")}
    else
      {:cont, socket}
    end
  end
end
