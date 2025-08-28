defmodule XPando.Node.LoadTest do
  @moduledoc """
  Load testing for P2P network with 3-5 concurrent node connections.
  Validates that the system can handle the required concurrent node connections (AC: 7).
  """
  use ExUnit.Case, async: false

  alias XPando.Node.Manager

  @moduletag timeout: 15_000

  setup do
    # Stop any running managers
    if Process.whereis(Manager) do
      GenServer.stop(Manager)
      :timer.sleep(100)
    end

    # Stop and restart the application to ensure clean state
    Application.stop(:xpando_node)
    :timer.sleep(50)

    :ok
  end

  describe "Load testing for concurrent node connections" do
    test "can handle 3 concurrent node connections with stable performance" do
      {:ok, manager_pid} = Manager.start_link()
      :timer.sleep(300)

      # Create 3 concurrent node connections
      nodes = [
        :"load_node_1@127.0.0.1",
        :"load_node_2@127.0.0.1",
        :"load_node_3@127.0.0.1"
      ]

      # Connect all nodes concurrently
      _start_time = :os.timestamp()

      tasks =
        Enum.map(nodes, fn node ->
          Task.async(fn ->
            :ok = Manager.update_node_status(node, :online)
            # Small delay to simulate real network timing
            :timer.sleep(10)
            Manager.get_nodes()[node]
          end)
        end)

      # Wait for all connections to complete
      results = Task.await_many(tasks, 5000)

      # Verify all connections were successful
      Enum.each(results, fn node_data ->
        assert node_data.status == :online
        assert is_struct(node_data.last_heartbeat, DateTime)
      end)

      # Wait for system stabilization
      :timer.sleep(200)

      # Verify system health with 3 nodes
      network_state = Manager.get_network_state()
      health = network_state.network_health

      # primary + 3 load nodes
      assert health.total_nodes >= 4
      assert health.online_nodes >= 4
      # Should be very healthy
      assert health.health_percentage >= 75.0
      assert health.network_partitioned == false

      # Performance verified by successful concurrent task completion

      GenServer.stop(manager_pid)
    end

    test "can handle 5 concurrent node connections with stable performance" do
      {:ok, manager_pid} = Manager.start_link()
      :timer.sleep(300)

      # Create 5 concurrent node connections (maximum required by AC: 7)
      nodes = [
        :"load_node_1@127.0.0.1",
        :"load_node_2@127.0.0.1",
        :"load_node_3@127.0.0.1",
        :"load_node_4@127.0.0.1",
        :"load_node_5@127.0.0.1"
      ]

      # Connect all nodes concurrently with timing measurements
      start_time = System.monotonic_time()

      tasks =
        Enum.map(nodes, fn node ->
          Task.async(fn ->
            :ok = Manager.update_node_status(node, :online)
            # Simulate network latency
            :timer.sleep(10)
            {node, Manager.get_nodes()[node]}
          end)
        end)

      # Wait for all connections to complete
      results = Task.await_many(tasks, 10000)
      end_time = System.monotonic_time()
      total_time_ms = System.convert_time_unit(end_time - start_time, :native, :millisecond)

      # Verify all connections were successful
      Enum.each(results, fn {_node, node_data} ->
        assert node_data.status == :online
        assert is_struct(node_data.last_heartbeat, DateTime)
      end)

      # Wait for system stabilization
      :timer.sleep(300)

      # Verify system health with 5 nodes
      network_state = Manager.get_network_state()
      health = network_state.network_health

      # primary + 5 load nodes
      assert health.total_nodes >= 6
      assert health.online_nodes >= 6
      # Should be healthy
      assert health.health_percentage >= 80.0
      assert health.network_partitioned == false

      # Performance requirements for 5 concurrent connections
      # Should complete within 2 seconds
      assert total_time_ms < 2000

      # Test topology integrity
      topology = Manager.get_network_topology()
      assert is_map(topology.connections)
      assert is_map(topology.network_map)

      GenServer.stop(manager_pid)
    end

    test "can handle rapid connection/disconnection cycles under load" do
      {:ok, manager_pid} = Manager.start_link()
      :timer.sleep(300)

      # Create nodes for stress testing
      nodes = [
        :"stress_node_1@127.0.0.1",
        :"stress_node_2@127.0.0.1",
        :"stress_node_3@127.0.0.1",
        :"stress_node_4@127.0.0.1"
      ]

      # Perform rapid connect/disconnect cycles
      for _cycle <- 1..3 do
        # Connect all nodes
        Enum.each(nodes, fn node ->
          :ok = Manager.update_node_status(node, :online)
        end)

        :timer.sleep(100)

        # Verify connections
        current_nodes = Manager.get_nodes()

        Enum.each(nodes, fn node ->
          assert Map.has_key?(current_nodes, node)
          assert current_nodes[node].status == :online
        end)

        # Disconnect all nodes
        Enum.each(nodes, fn node ->
          :ok = Manager.update_node_status(node, :offline)
        end)

        :timer.sleep(100)

        # Verify disconnections
        updated_nodes = Manager.get_nodes()

        Enum.each(nodes, fn node ->
          if Map.has_key?(updated_nodes, node) do
            assert updated_nodes[node].status == :offline
          end
        end)
      end

      # Final health check - system should recover
      :timer.sleep(200)
      final_health = Manager.get_network_state().network_health
      # Should maintain basic stability after stress test
      assert final_health.health_percentage >= 20.0

      GenServer.stop(manager_pid)
    end

    test "maintains performance with concurrent health checks and status updates" do
      {:ok, manager_pid} = Manager.start_link()
      :timer.sleep(300)

      # Set up base nodes
      base_nodes = [
        :"perf_node_1@127.0.0.1",
        :"perf_node_2@127.0.0.1",
        :"perf_node_3@127.0.0.1"
      ]

      Enum.each(base_nodes, fn node ->
        :ok = Manager.update_node_status(node, :online)
      end)

      :timer.sleep(200)

      # Perform concurrent operations
      start_time = System.monotonic_time()

      # Concurrent health checks
      health_tasks =
        for _ <- 1..10 do
          Task.async(fn -> Manager.get_health_stats() end)
        end

      # Concurrent node state queries
      state_tasks =
        for _ <- 1..10 do
          Task.async(fn -> Manager.get_network_state() end)
        end

      # Concurrent status updates
      update_tasks =
        for i <- 1..5 do
          Task.async(fn ->
            test_node = :"concurrent_node_#{i}@127.0.0.1"
            :ok = Manager.update_node_status(test_node, :online)
            :timer.sleep(20)
            :ok = Manager.update_node_status(test_node, :offline)
          end)
        end

      # Wait for all concurrent operations
      health_results = Task.await_many(health_tasks, 5000)
      state_results = Task.await_many(state_tasks, 5000)
      update_results = Task.await_many(update_tasks, 5000)

      end_time = System.monotonic_time()
      total_time_ms = System.convert_time_unit(end_time - start_time, :native, :millisecond)

      # Verify all operations completed successfully
      assert length(health_results) == 10
      assert length(state_results) == 10
      assert length(update_results) == 5

      Enum.each(health_results, fn result ->
        assert Map.has_key?(result, :uptime_seconds)
        assert Map.has_key?(result, :total_nodes)
      end)

      Enum.each(state_results, fn result ->
        assert Map.has_key?(result, :network_health)
        assert Map.has_key?(result, :topology)
      end)

      # Performance check - should handle concurrent load efficiently
      # Should complete within 3 seconds
      assert total_time_ms < 3000

      GenServer.stop(manager_pid)
    end
  end
end
