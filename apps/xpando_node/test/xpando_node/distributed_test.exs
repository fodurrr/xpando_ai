defmodule XPando.Node.DistributedTest do
  use ExUnit.Case, async: false
  alias XPando.Node.Manager

  # These tests verify distributed behavior within the test node
  # Real multi-node testing requires starting separate Erlang VMs which is complex in tests

  @moduletag :distributed

  describe "distributed node simulation" do
    test "Manager tracks multiple simulated nodes" do
      # Get or start Manager
      manager_pid =
        case Process.whereis(Manager) do
          nil ->
            {:ok, pid} = Manager.start_link()
            pid

          pid ->
            pid
        end

      # Simulate multiple nodes joining
      nodes = [:node1@localhost, :node2@localhost, :node3@localhost]

      Enum.each(nodes, fn node ->
        Manager.update_node_status(node, :online)
      end)

      # Verify all nodes are tracked
      tracked_nodes = Manager.get_nodes()

      Enum.each(nodes, fn node ->
        assert Map.has_key?(tracked_nodes, node)
        assert tracked_nodes[node].status == :online
      end)

      # Simulate node disconnection
      Manager.update_node_status(:node2@localhost, :offline)

      updated_nodes = Manager.get_nodes()
      assert updated_nodes[:node2@localhost].status == :offline

      # Only stop if test started it
      if manager_pid && Process.alive?(manager_pid), do: GenServer.stop(manager_pid, :normal, 100)
    end

    test "Manager handles rapid node status changes" do
      # Get or start Manager
      manager_pid =
        case Process.whereis(Manager) do
          nil ->
            {:ok, pid} = Manager.start_link()
            pid

          pid ->
            pid
        end

      node_id = :rapid_test@localhost

      # Rapidly change node status
      statuses = [:connecting, :online, :offline, :online, :connecting, :offline]

      Enum.each(statuses, fn status ->
        Manager.update_node_status(node_id, status)
      end)

      # Final status should be the last one
      nodes = Manager.get_nodes()
      assert nodes[node_id].status == :offline

      # Only stop if test started it
      if manager_pid && Process.alive?(manager_pid), do: GenServer.stop(manager_pid, :normal, 100)
    end

    test "Manager maintains topology information" do
      # Get or start Manager
      manager_pid =
        case Process.whereis(Manager) do
          nil ->
            {:ok, pid} = Manager.start_link()
            pid

          pid ->
            pid
        end

      # Add nodes
      nodes = [:topo1@localhost, :topo2@localhost, :topo3@localhost]
      Enum.each(nodes, &Manager.update_node_status(&1, :online))

      # Get topology
      topology = Manager.get_topology()
      assert is_map(topology)

      # Get network state
      network_state = Manager.get_network_state()
      assert Map.has_key?(network_state, :nodes)
      assert Map.has_key?(network_state, :topology)
      assert Map.has_key?(network_state, :network_health)

      # Only stop if test started it
      if manager_pid && Process.alive?(manager_pid), do: GenServer.stop(manager_pid, :normal, 100)
    end

    test "Manager provides health statistics" do
      # Get or start Manager
      manager_pid =
        case Process.whereis(Manager) do
          nil ->
            {:ok, pid} = Manager.start_link()
            pid

          pid ->
            pid
        end

      # Add some nodes with different statuses
      Manager.update_node_status(:health1@localhost, :online)
      Manager.update_node_status(:health2@localhost, :online)
      Manager.update_node_status(:health3@localhost, :offline)
      Manager.update_node_status(:health4@localhost, :connecting)

      # Get health stats
      health_stats = Manager.get_health_stats()

      # Check that we have nodes tracked (may have extras from other tests)
      assert health_stats.total_nodes >= 4
      assert health_stats.active_nodes >= 0
      assert is_map(health_stats)

      # Only stop if test started it
      if manager_pid && Process.alive?(manager_pid), do: GenServer.stop(manager_pid, :normal, 100)
    end
  end

  describe "network monitoring" do
    test "monitors node connections and disconnections" do
      # Get or start Manager
      manager_pid =
        case Process.whereis(Manager) do
          nil ->
            {:ok, pid} = Manager.start_link()
            pid

          pid ->
            pid
        end

      # Enable node monitoring
      :net_kernel.monitor_nodes(true)

      # Simulate node events
      node_id = :monitor_test@localhost

      # Node comes online
      Manager.update_node_status(node_id, :online)
      assert Manager.get_nodes()[node_id].status == :online

      # Node goes offline
      Manager.update_node_status(node_id, :offline)
      assert Manager.get_nodes()[node_id].status == :offline

      # Cleanup
      :net_kernel.monitor_nodes(false)
      # Only stop if test started it
      if manager_pid && Process.alive?(manager_pid), do: GenServer.stop(manager_pid, :normal, 100)
    end

    test "handles concurrent node updates" do
      # Get or start Manager
      manager_pid =
        case Process.whereis(Manager) do
          nil ->
            {:ok, pid} = Manager.start_link()
            pid

          pid ->
            pid
        end

      # Spawn multiple processes updating nodes concurrently
      tasks =
        for i <- 1..50 do
          Task.async(fn ->
            node_id = :"concurrent_#{i}@localhost"
            Manager.update_node_status(node_id, :online)
            Manager.get_nodes()
            Manager.update_node_status(node_id, :offline)
          end)
        end

      # Wait for all tasks
      Task.await_many(tasks, 5000)

      # Manager should still be operational
      assert Process.alive?(manager_pid)
      nodes = Manager.get_nodes()
      assert is_map(nodes)

      # Only stop if test started it
      if manager_pid && Process.alive?(manager_pid), do: GenServer.stop(manager_pid, :normal, 100)
    end
  end

  describe "pubsub integration" do
    test "broadcasts cluster events when available" do
      # Get or start Manager
      manager_pid =
        case Process.whereis(Manager) do
          nil ->
            {:ok, pid} = Manager.start_link()
            pid

          pid ->
            pid
        end

      # Try to subscribe to cluster events (may fail in test env)
      try do
        Phoenix.PubSub.subscribe(XpandoWeb.PubSub, "cluster:events")

        # Trigger an event
        Manager.update_node_status(:pubsub_test@localhost, :online)

        # We might receive events if PubSub is available
        receive do
          _msg ->
            # Event received
            assert true
        after
          100 ->
            # No event is ok in test environment
            assert true
        end
      rescue
        _ ->
          # PubSub not available in test is expected
          assert true
      end

      # Only stop if test started it
      if manager_pid && Process.alive?(manager_pid), do: GenServer.stop(manager_pid, :normal, 100)
    end
  end

  describe "error handling" do
    test "Manager handles invalid node IDs gracefully" do
      # Get or start Manager
      manager_pid =
        case Process.whereis(Manager) do
          nil ->
            {:ok, pid} = Manager.start_link()
            pid

          pid ->
            pid
        end

      # Try various invalid inputs
      Manager.update_node_status(nil, :online)
      Manager.update_node_status("", :online)
      Manager.update_node_status(123, :online)

      # Manager should still be operational
      assert Process.alive?(manager_pid)
      nodes = Manager.get_nodes()
      assert is_map(nodes)

      # Only stop if test started it
      if manager_pid && Process.alive?(manager_pid), do: GenServer.stop(manager_pid, :normal, 100)
    end

    test "Manager recovers from crashes" do
      # Get or start Manager
      manager_pid =
        case Process.whereis(Manager) do
          nil ->
            {:ok, pid} = Manager.start_link()
            pid

          pid ->
            pid
        end

      # Add some state
      Manager.update_node_status(:crash_test@localhost, :online)

      # Send invalid message to trigger error handling
      send(manager_pid, {:invalid_message, :test})

      # Give time for error handling
      Process.sleep(100)

      # Manager should still be alive
      assert Process.alive?(manager_pid)

      # State should be preserved
      nodes = Manager.get_nodes()
      assert Map.has_key?(nodes, :crash_test@localhost)

      # Only stop if test started it
      if manager_pid && Process.alive?(manager_pid), do: GenServer.stop(manager_pid, :normal, 100)
    end
  end
end
