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

  pipeline :ensure_auth do
    plug LtzfApWeb.Plugs.Authenticate
  end

  pipeline :ensure_superuser do
    plug LtzfApWeb.Plugs.Authenticate
    plug LtzfApWeb.Plugs.AuthorizeSuperuser
  end

  scope "/", LtzfApWeb do
    pipe_through :browser

    # Public routes
    get "/", PageController, :home

    # Session routes
    get "/login", SessionController, :new
    post "/login", SessionController, :create
    delete "/logout", SessionController, :delete
    get "/register", SessionController, :register
    post "/register", SessionController, :create_user
  end

  scope "/", LtzfApWeb do
    pipe_through [:browser, :ensure_auth]

    # Protected routes - Dashboard is now the main authenticated page
    get "/dashboard", DashboardController, :index

    # Settings routes
    get "/settings", SettingsController, :index
    put "/settings", SettingsController, :update
    put "/settings/password", SettingsController, :update_password
    get "/settings/test", SettingsController, :test_connection

    # Data management routes
    get "/data_management", DataManagementController, :index
    get "/data_management/vorgaenge", DataManagementController, :vorgaenge
    get "/data_management/vorgang/:id", DataManagementController, :vorgang
    get "/data_management/sitzungen", DataManagementController, :sitzungen
    get "/data_management/sitzung/:id", DataManagementController, :sitzung

    get "/data_management/enumerations", DataManagementController, :enumerations

    # Proxy endpoints for API calls (to handle CORS headers)
    get "/api/proxy/vorgang", DataManagementController, :proxy_vorgang
    get "/api/proxy/sitzung", DataManagementController, :proxy_sitzung


  end

  scope "/", LtzfApWeb do
    pipe_through [:browser, :ensure_superuser]

    # Superuser-only routes
    resources "/users", UserController, only: [:index, :delete]
    post "/users/:id/deactivate", UserController, :deactivate
    post "/users/:id/activate", UserController, :activate
  end

  # Other scopes may use custom stacks.
  # scope "/api", LtzfApWeb do
  #   pipe_through :api
  # end
end
