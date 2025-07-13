import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ltzf_ap, LtzfApWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "w3pvN3yp843PYonwDGyywkBt9oaOv52wr9FusPpGw97Ylus3JkOuBKgE/aJyK01M",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Default backend URL for tests (can be overridden by environment variable)
config :ltzf_ap, :default_backend_url, System.get_env("DEFAULT_BACKEND_URL")

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
