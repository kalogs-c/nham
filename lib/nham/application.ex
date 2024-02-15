defmodule Nham.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      NhamWeb.Telemetry,
      Nham.Repo,
      {DNSCluster, query: Application.get_env(:nham, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Nham.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Nham.Finch},
      # Start a worker by calling: Nham.Worker.start_link(arg)
      # {Nham.Worker, arg},
      # Start to serve requests, typically the last entry
      NhamWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Nham.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NhamWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
