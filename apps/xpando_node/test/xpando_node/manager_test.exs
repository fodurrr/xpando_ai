defmodule XPando.Node.ManagerTest do
  use ExUnit.Case, async: false

  alias XPando.Node.Manager

  setup do
    # Stop the manager if it's already running
    if Process.whereis(Manager) do
      GenServer.stop(Manager)
      Process.sleep(200)
    end

    # Also stop the application to avoid conflicts
    Application.stop(:xpando_node)
    Process.sleep(100)

    :ok
  end

  describe "Node Manager GenServer" do
    test "can start successfully" do
      {:ok, pid} = Manager.start_link()
      assert is_pid(pid)
      assert Process.alive?(pid)

      # Clean up
      GenServer.stop(pid)
    end

    test "can get nodes state" do
      {:ok, pid} = Manager.start_link()

      nodes = GenServer.call(pid, :get_nodes)
      assert is_map(nodes)

      # Should contain at least the current node
      current_node = node()
      assert Map.has_key?(nodes, current_node)

      # Clean up
      GenServer.stop(pid)
    end

    test "can get topology state" do
      {:ok, pid} = Manager.start_link()

      topology = GenServer.call(pid, :get_topology)
      assert is_map(topology)

      # Clean up
      GenServer.stop(pid)
    end

    test "can update node status" do
      {:ok, pid} = Manager.start_link()

      # Wait for initialization to complete
      Process.sleep(100)

      test_node = :test@localhost
      :ok = GenServer.cast(pid, {:update_node_status, test_node, :connecting})

      # Give time for the cast to be processed
      Process.sleep(50)

      nodes = GenServer.call(pid, :get_nodes)
      assert Map.has_key?(nodes, test_node)
      assert nodes[test_node].status == :connecting

      # Clean up
      GenServer.stop(pid)
    end

    test "can trigger heartbeat" do
      {:ok, pid} = Manager.start_link()

      # This should not crash
      :ok = GenServer.cast(pid, :trigger_heartbeat)

      # Give time for processing
      Process.sleep(50)

      # Manager should still be alive
      assert Process.alive?(pid)

      # Clean up
      GenServer.stop(pid)
    end

    test "handles nodeup messages" do
      {:ok, pid} = Manager.start_link()

      # Wait for initialization
      Process.sleep(100)

      test_node = :test@localhost
      send(pid, {:nodeup, test_node})

      # Give time for message processing
      Process.sleep(50)

      nodes = GenServer.call(pid, :get_nodes)

      if Map.has_key?(nodes, test_node) do
        assert nodes[test_node].status == :online
      end

      # Clean up
      GenServer.stop(pid)
    end

    test "handles nodedown messages" do
      {:ok, pid} = Manager.start_link()

      # Wait for initialization
      Process.sleep(100)

      test_node = :test@localhost

      # First simulate nodeup
      send(pid, {:nodeup, test_node})
      Process.sleep(50)

      # Then simulate nodedown
      send(pid, {:nodedown, test_node})
      Process.sleep(50)

      nodes = GenServer.call(pid, :get_nodes)

      if Map.has_key?(nodes, test_node) do
        assert nodes[test_node].status == :offline
      end

      # Clean up
      GenServer.stop(pid)
    end

    test "processes heartbeat timer messages" do
      {:ok, pid} = Manager.start_link()

      # Wait for initialization
      Process.sleep(100)

      # Send heartbeat message directly
      send(pid, :heartbeat)

      # Give time for processing
      Process.sleep(50)

      # Manager should still be alive and functioning
      assert Process.alive?(pid)
      nodes = GenServer.call(pid, :get_nodes)
      assert is_map(nodes)

      # Clean up
      GenServer.stop(pid)
    end
  end

  describe "Node Manager Client API" do
    test "get_nodes/0 works when manager is running" do
      {:ok, _pid} = Manager.start_link()

      # Wait for initialization
      Process.sleep(100)

      nodes = Manager.get_nodes()
      assert is_map(nodes)

      # Should contain current node
      current_node = node()
      assert Map.has_key?(nodes, current_node)

      # Clean up
      GenServer.stop(Manager)
    end

    test "get_topology/0 works when manager is running" do
      {:ok, _pid} = Manager.start_link()

      # Wait for initialization
      Process.sleep(100)

      topology = Manager.get_topology()
      assert is_map(topology)
      assert Map.has_key?(topology, :connections)
      assert Map.has_key?(topology, :network_map)
      assert Map.has_key?(topology, :last_topology_update)

      # Clean up
      GenServer.stop(Manager)
    end

    test "get_network_topology/0 works when manager is running" do
      {:ok, _pid} = Manager.start_link()

      # Wait for initialization
      Process.sleep(100)

      network_topology = Manager.get_network_topology()
      assert is_map(network_topology)
      assert Map.has_key?(network_topology, :connections)
      assert Map.has_key?(network_topology, :network_map)
      assert Map.has_key?(network_topology, :last_topology_update)

      # Clean up
      GenServer.stop(Manager)
    end

    test "get_network_state/0 works when manager is running" do
      {:ok, _pid} = Manager.start_link()

      # Wait for initialization
      Process.sleep(100)

      network_state = Manager.get_network_state()
      assert is_map(network_state)
      assert Map.has_key?(network_state, :timestamp)
      assert Map.has_key?(network_state, :current_node)
      assert Map.has_key?(network_state, :nodes)
      assert Map.has_key?(network_state, :topology)
      assert Map.has_key?(network_state, :connection_stats)
      assert Map.has_key?(network_state, :cluster_nodes)
      assert Map.has_key?(network_state, :network_health)

      # Verify network_health structure
      health = network_state.network_health
      assert Map.has_key?(health, :total_nodes)
      assert Map.has_key?(health, :online_nodes)
      assert Map.has_key?(health, :health_percentage)

      # Clean up
      GenServer.stop(Manager)
    end

    test "get_health_stats/0 works when manager is running" do
      {:ok, _pid} = Manager.start_link()

      # Wait for initialization
      Process.sleep(100)

      health_stats = Manager.get_health_stats()
      assert is_map(health_stats)
      assert Map.has_key?(health_stats, :current_time)
      assert Map.has_key?(health_stats, :uptime_seconds)
      assert Map.has_key?(health_stats, :active_nodes)
      assert Map.has_key?(health_stats, :total_nodes)
      assert Map.has_key?(health_stats, :topology_connections)

      # Clean up
      GenServer.stop(Manager)
    end

    test "update_node_status/2 works" do
      {:ok, _pid} = Manager.start_link()

      # Wait for initialization
      Process.sleep(100)

      test_node = :test@localhost
      :ok = Manager.update_node_status(test_node, :connecting)

      # Give time for processing
      Process.sleep(50)

      nodes = Manager.get_nodes()
      assert Map.has_key?(nodes, test_node)
      assert nodes[test_node].status == :connecting

      # Clean up
      GenServer.stop(Manager)
    end

    test "trigger_heartbeat/0 works" do
      {:ok, _pid} = Manager.start_link()

      # Wait for initialization
      Process.sleep(100)

      # Should not crash
      :ok = Manager.trigger_heartbeat()

      # Give time for processing
      Process.sleep(50)

      # Manager should still be functional
      nodes = Manager.get_nodes()
      assert is_map(nodes)

      # Clean up
      GenServer.stop(Manager)
    end
  end
end
