defmodule LtzfAp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LtzfApWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:ltzf_ap, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LtzfAp.PubSub},
      # Start our custom services
      LtzfAp.ApiClient,
      LtzfAp.Session,
      # Start to serve requests, typically the last entry
      LtzfApWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LtzfAp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LtzfApWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
