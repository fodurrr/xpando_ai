defmodule XPando.Node.ClusterIntegrationTest do
  @moduledoc """
  End-to-end integration tests for multi-node cluster formation.
  Tests the P2P network discovery and communication capabilities.
  """
  use ExUnit.Case, async: false

  alias XPando.Node.Manager

  @moduletag timeout: 10_000

  defp safe_stop_manager(pid) when is_pid(pid) do
    try do
      GenServer.stop(pid, :normal, 1000)
    catch
      :exit, _ -> Process.exit(pid, :kill)
    end
  end

  defp safe_stop_manager(_), do: :ok

  setup do
    # Stop any running managers with timeout
    manager_pid = Process.whereis(Manager)
    safe_stop_manager(manager_pid)
    :timer.sleep(100)

    # Stop and restart the application to ensure clean state
    Application.stop(:xpando_node)
    :timer.sleep(50)

    :ok
  end

  describe "Multi-node cluster formation" do
    test "can start primary node and form cluster" do
      # Start the primary node manager
      {:ok, primary_pid} = Manager.start_link()
      assert Process.alive?(primary_pid)

      # Wait for initialization
      :timer.sleep(500)

      # Check initial state
      nodes = Manager.get_nodes()
      assert is_map(nodes)
      assert Map.has_key?(nodes, node())

      # Check topology
      topology = Manager.get_topology()
      assert is_map(topology)
      assert Map.has_key?(topology, :connections)
      assert Map.has_key?(topology, :network_map)

      # Check network state
      network_state = Manager.get_network_state()
      assert network_state.current_node == node()
      assert network_state.network_health.total_nodes >= 1

      safe_stop_manager(primary_pid)
    end

    test "can detect node connections and disconnections" do
      # Start the primary node manager
      {:ok, primary_pid} = Manager.start_link()
      :timer.sleep(500)

      # Simulate a node joining
      test_node = :"test_node@127.0.0.1"

      # Note: PubSub integration tested separately due to app dependencies

      # Update node status to simulate a connection
      :ok = Manager.update_node_status(test_node, :online)
      :timer.sleep(100)

      # Check that node was added
      nodes = Manager.get_nodes()
      assert Map.has_key?(nodes, test_node)
      assert nodes[test_node].status == :online

      # Verify the status change was processed

      # Simulate node disconnection
      :ok = Manager.update_node_status(test_node, :offline)
      :timer.sleep(100)

      # Verify node status updated
      nodes = Manager.get_nodes()
      assert nodes[test_node].status == :offline

      safe_stop_manager(primary_pid)
    end

    test "can handle heartbeat monitoring and health checks" do
      {:ok, primary_pid} = Manager.start_link()
      :timer.sleep(500)

      # Trigger manual heartbeat
      :ok = Manager.trigger_heartbeat()
      :timer.sleep(100)

      # Get health statistics
      health_stats = Manager.get_health_stats()
      assert health_stats.uptime_seconds >= 0
      assert health_stats.total_nodes >= 1
      assert health_stats.active_nodes >= 1

      safe_stop_manager(primary_pid)
    end

    test "can track network topology changes" do
      {:ok, primary_pid} = Manager.start_link()
      :timer.sleep(500)

      # Test topology changes without PubSub dependency

      # Simulate node connections that would trigger topology updates
      test_node1 = :"node1@127.0.0.1"
      test_node2 = :"node2@127.0.0.1"

      # Add first node
      :ok = Manager.update_node_status(test_node1, :online)
      :timer.sleep(100)

      # Add second node
      :ok = Manager.update_node_status(test_node2, :online)
      :timer.sleep(100)

      # Get network topology
      network_state = Manager.get_network_state()
      # primary + 2 test nodes
      assert network_state.network_health.total_nodes >= 3

      # Verify topology structure
      topology = Manager.get_network_topology()
      assert is_map(topology.connections)
      assert is_map(topology.network_map)

      safe_stop_manager(primary_pid)
    end

    test "can handle connection health monitoring with multiple nodes" do
      {:ok, primary_pid} = Manager.start_link()
      :timer.sleep(500)

      # Add multiple test nodes
      test_nodes = [
        :"node1@127.0.0.1",
        :"node2@127.0.0.1",
        :"node3@127.0.0.1"
      ]

      # Connect all nodes
      Enum.each(test_nodes, fn node ->
        :ok = Manager.update_node_status(node, :online)
        :timer.sleep(50)
      end)

      # Wait for all connections to be established
      :timer.sleep(200)

      # Get network health
      network_state = Manager.get_network_state()
      health = network_state.network_health

      # primary + 3 test nodes
      assert health.total_nodes >= 4
      assert health.online_nodes >= 4
      assert health.health_percentage > 0
      assert health.network_partitioned == false

      # Test disconnection scenarios
      :ok = Manager.update_node_status(List.first(test_nodes), :offline)
      :timer.sleep(100)

      # Health should reflect the disconnection
      updated_health = Manager.get_network_state().network_health
      assert updated_health.offline_nodes >= 1
      assert updated_health.online_nodes < health.online_nodes

      safe_stop_manager(primary_pid)
    end
  end

  describe "Network resilience testing" do
    test "can recover from temporary network partitions" do
      {:ok, primary_pid} = Manager.start_link()
      :timer.sleep(500)

      # Create initial topology
      test_nodes = [:"node1@127.0.0.1", :"node2@127.0.0.1"]

      Enum.each(test_nodes, fn node ->
        :ok = Manager.update_node_status(node, :online)
      end)

      :timer.sleep(200)

      # Verify initial healthy state
      initial_health = Manager.get_network_state().network_health
      assert initial_health.network_partitioned == false

      # Simulate network partition (nodes go offline)
      Enum.each(test_nodes, fn node ->
        :ok = Manager.update_node_status(node, :offline)
      end)

      :timer.sleep(100)

      # Should detect partition
      partition_health = Manager.get_network_state().network_health
      assert partition_health.offline_nodes >= 2

      # Simulate recovery (nodes come back online)
      Enum.each(test_nodes, fn node ->
        :ok = Manager.update_node_status(node, :online)
      end)

      :timer.sleep(200)

      # Should recover to healthy state
      recovery_health = Manager.get_network_state().network_health
      assert recovery_health.online_nodes >= initial_health.online_nodes

      safe_stop_manager(primary_pid)
    end
  end
end
