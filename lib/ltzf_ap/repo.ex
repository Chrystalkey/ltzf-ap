defmodule LtzfAp.Repo do
  use Ecto.Repo,
    otp_app: :ltzf_ap,
    adapter: Ecto.Adapters.SQLite3
end
