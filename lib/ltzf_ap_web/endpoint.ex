defmodule LtzfApWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :ltzf_ap

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_ltzf_ap_key",
    signing_salt: "CPdtn9EO",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :ltzf_ap,
    gzip: false,
    only: LtzfApWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :ltzf_ap
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options

  # CORS configuration to expose custom headers
  plug :cors_headers

  plug LtzfApWeb.Router

  # CORS headers function
  defp cors_headers(conn, _opts) do
    # Handle OPTIONS preflight requests
    if conn.method == "OPTIONS" do
      conn
      |> put_resp_header("access-control-allow-origin", "*")
      |> put_resp_header("access-control-allow-methods", "GET, POST, PUT, DELETE, OPTIONS")
      |> put_resp_header("access-control-allow-headers", "Content-Type, Authorization, X-API-Key")
      |> put_resp_header("access-control-expose-headers", "x-total-count, x-total-pages, x-page, x-per-page, link")
      |> send_resp(200, "")
    else
      # For actual requests, just expose the headers
      conn
      |> put_resp_header("access-control-expose-headers", "x-total-count, x-total-pages, x-page, x-per-page, link")
    end
  end
end
