defmodule LiveSlides.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LiveSlidesWeb.Telemetry,
      LiveSlides.Repo,
      {DNSCluster, query: Application.get_env(:live_slides, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LiveSlides.PubSub},
      {DynamicSupervisor, name: LiveSlides.Presentations.PresentationSupervisor},
      LiveSlidesWeb.Presence,
      # Start the Finch HTTP client for sending emails
      {Finch, name: LiveSlides.Finch},
      # Start a worker by calling: LiveSlides.Worker.start_link(arg)
      # {LiveSlides.Worker, arg},
      # Start to serve requests, typically the last entry
      LiveSlidesWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveSlides.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LiveSlidesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
