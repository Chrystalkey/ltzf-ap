defmodule LtzfApWeb.Router do
  use LtzfApWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LtzfApWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LtzfApWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/login", LoginLive
    live "/dashboard", DashboardLive
    live "/key-management", KeyManagementLive
    live "/vorgaenge", VorgaengeLive
    live "/sitzungen", SitzungenLive
    live "/enumerations", EnumerationsLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", LtzfApWeb do
  #   pipe_through :api
  # end
end
