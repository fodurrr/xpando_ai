defmodule XpandoNode.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Cluster supervisor
      {Cluster.Supervisor, [topologies(), [name: XpandoNode.ClusterSupervisor]]},
      # Start the Node Manager
      {XPando.Node.Manager, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: XpandoNode.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp topologies do
    Application.get_env(:libcluster, :topologies) || []
  end
end
