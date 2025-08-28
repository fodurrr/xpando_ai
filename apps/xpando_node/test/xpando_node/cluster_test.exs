defmodule XpandoNode.ClusterTest do
  use ExUnit.Case, async: false

  describe "cluster configuration" do
    test "libcluster configuration is loaded" do
      # Test that libcluster configuration exists
      topologies = Application.get_env(:libcluster, :topologies)
      assert is_list(topologies)
      assert Keyword.has_key?(topologies, :test_topology)

      config = Keyword.get(topologies, :test_topology)
      assert config[:strategy] == Cluster.Strategy.Gossip
      assert is_list(config[:config])
    end

    test "XpandoNode application can start" do
      # Test that the application can be started
      Application.stop(:xpando_node)
      result = Application.ensure_all_started(:xpando_node)

      case result do
        {:ok, apps} -> assert :xpando_node in apps
        {:error, {:already_started, :xpando_node}} -> :ok
        other -> flunk("Unexpected result: #{inspect(other)}")
      end

      # Ensure application is running
      Application.start(:xpando_node)
    end

    test "cluster supervisor configuration is valid" do
      # Test that the cluster supervisor can be configured
      topologies = Application.get_env(:libcluster, :topologies) || []

      # This should not raise an error
      children = [{Cluster.Supervisor, [topologies, [name: TestClusterSupervisor]]}]
      opts = [strategy: :one_for_one, name: TestSupervisor]

      {:ok, supervisor_pid} = Supervisor.start_link(children, opts)
      assert is_pid(supervisor_pid)

      # Clean up
      Supervisor.stop(supervisor_pid)
    end
  end
end
