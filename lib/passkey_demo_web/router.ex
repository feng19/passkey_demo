defmodule PasskeyDemoWeb.Router do
  use PasskeyDemoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PasskeyDemoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :auth do
    plug PasskeyDemoWeb.Auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PasskeyDemoWeb do
    pipe_through :browser

    get "/login/:token", PageController, :login
    get "/logout", PageController, :logout

    live_session :check_session, on_mount: PasskeyDemoWeb.LiveAuth do
      live "/", PasskeyLive
    end
  end

  scope "/", PasskeyDemoWeb do
    pipe_through [:browser, :auth]
    get "/me", PageController, :me
  end

  # Other scopes may use custom stacks.
  # scope "/api", PasskeyDemoWeb do
  #   pipe_through :api
  # end
end
