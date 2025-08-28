defmodule XPando.Node.PerformanceTest do
  use ExUnit.Case
  alias XPando.Node.Manager

  @moduletag :performance

  describe "message throughput tests" do
    test "handles high message volume without degradation" do
      manager_pid =
        case Process.whereis(Manager) do
          nil ->
            {:ok, pid} = Manager.start_link()
            pid

          pid ->
            pid
        end

      # Number of messages to send
      message_count = 1000
      nodes = [:perf1@localhost, :perf2@localhost, :perf3@localhost]

      # Start timing
      start_time = System.monotonic_time(:millisecond)

      # Send messages concurrently
      tasks =
        for node <- nodes, _i <- 1..div(message_count, 3) do
          Task.async(fn ->
            Manager.update_node_status(node, Enum.random([:online, :offline, :connecting]))
          end)
        end

      # Wait for all tasks
      Task.await_many(tasks, 10_000)

      # Calculate throughput
      end_time = System.monotonic_time(:millisecond)
      duration_ms = end_time - start_time
      throughput = message_count / (duration_ms / 1000)

      # Assert minimum throughput (messages per second)
      assert throughput > 100, "Throughput too low: #{throughput} msg/s"

      # Verify manager is still responsive
      assert Manager.get_nodes() |> is_map()

      if manager_pid && Process.alive?(manager_pid), do: GenServer.stop(manager_pid, :normal, 100)
    end

    test "measures message latency under load" do
      manager_pid =
        case Process.whereis(Manager) do
          nil ->
            {:ok, pid} = Manager.start_link()
            pid

          pid ->
            pid
        end

      # Measure latencies for multiple messages
      latencies =
        for _ <- 1..100 do
          start = System.monotonic_time(:microsecond)
          Manager.update_node_status(:latency_test, :online)
          stop = System.monotonic_time(:microsecond)
          stop - start
        end

      # Calculate statistics
      avg_latency = Enum.sum(latencies) / length(latencies)
      max_latency = Enum.max(latencies)
      min_latency = Enum.min(latencies)

      # Convert to milliseconds
      avg_ms = avg_latency / 1000
      max_ms = max_latency / 1000

      # Assert latency requirements
      assert avg_ms < 10, "Average latency too high: #{avg_ms}ms"
      assert max_ms < 50, "Maximum latency too high: #{max_ms}ms"

      IO.puts("Latency stats - Avg: #{avg_ms}ms, Max: #{max_ms}ms, Min: #{min_latency / 1000}ms")

      if manager_pid && Process.alive?(manager_pid), do: GenServer.stop(manager_pid, :normal, 100)
    end

    test "concurrent node operations performance" do
      manager_pid =
        case Process.whereis(Manager) do
          nil ->
            {:ok, pid} = Manager.start_link()
            pid

          pid ->
            pid
        end

      # Create test nodes
      nodes = for i <- 1..50, do: :"perf_node_#{i}@localhost"

      # Measure concurrent update performance
      start_time = System.monotonic_time(:millisecond)

      # Concurrent updates
      tasks =
        Enum.map(nodes, fn node ->
          Task.async(fn ->
            # Simulate realistic node operations
            Manager.update_node_status(node, :connecting)
            Process.sleep(Enum.random(1..5))
            Manager.update_node_status(node, :online)
            Manager.get_nodes()
            Manager.get_network_state()
          end)
        end)

      # Wait for completion
      Task.await_many(tasks, 30_000)

      end_time = System.monotonic_time(:millisecond)
      total_time = end_time - start_time

      # Assert performance requirements
      assert total_time < 5000, "Concurrent operations took too long: #{total_time}ms"

      # Verify all nodes were processed (at least most should be online)
      final_nodes = Manager.get_nodes()
      online_count = Enum.count(final_nodes, fn {_k, v} -> v.status == :online end)
      # Allow for some timing differences - at least 90% should be online
      assert online_count >= div(length(nodes) * 9, 10)

      if manager_pid && Process.alive?(manager_pid), do: GenServer.stop(manager_pid, :normal, 100)
    end

    test "memory usage under sustained load" do
      manager_pid =
        case Process.whereis(Manager) do
          nil ->
            {:ok, pid} = Manager.start_link()
            pid

          pid ->
            pid
        end

      # Get initial memory
      initial_memory = :erlang.memory(:total)

      # Generate sustained load
      for batch <- 1..10 do
        tasks =
          for i <- 1..100 do
            Task.async(fn ->
              node_id = :"mem_test_#{batch}_#{i}@localhost"
              Manager.update_node_status(node_id, :online)
            end)
          end

        Task.await_many(tasks, 5000)

        # Small delay between batches
        Process.sleep(100)
      end

      # Force garbage collection
      :erlang.garbage_collect()
      Process.sleep(500)

      # Measure final memory
      final_memory = :erlang.memory(:total)
      # Convert to MB
      memory_growth = (final_memory - initial_memory) / (1024 * 1024)

      # Assert reasonable memory usage
      assert memory_growth < 100, "Memory growth too high: #{memory_growth}MB"

      IO.puts("Memory growth: #{Float.round(memory_growth, 2)}MB")

      if manager_pid && Process.alive?(manager_pid), do: GenServer.stop(manager_pid, :normal, 100)
    end
  end

  describe "network topology performance" do
    test "topology updates scale with node count" do
      manager_pid =
        case Process.whereis(Manager) do
          nil ->
            {:ok, pid} = Manager.start_link()
            pid

          pid ->
            pid
        end

      # Build topology with increasing nodes
      topology_times =
        for node_count <- [10, 20, 30, 40, 50] do
          nodes = for i <- 1..node_count, do: :"topo_#{i}@localhost"

          # Add all nodes
          Enum.each(nodes, fn node ->
            Manager.update_node_status(node, :online)
          end)

          # Measure topology retrieval time
          start = System.monotonic_time(:microsecond)
          _topology = Manager.get_topology()
          stop = System.monotonic_time(:microsecond)

          # Convert to ms
          {node_count, (stop - start) / 1000}
        end

      # Verify topology operations remain fast
      Enum.each(topology_times, fn {count, time_ms} ->
        assert time_ms < 100, "Topology retrieval too slow for #{count} nodes: #{time_ms}ms"
      end)

      # Print performance curve
      IO.puts("Topology performance:")

      Enum.each(topology_times, fn {count, time_ms} ->
        IO.puts("  #{count} nodes: #{Float.round(time_ms, 2)}ms")
      end)

      if manager_pid && Process.alive?(manager_pid), do: GenServer.stop(manager_pid, :normal, 100)
    end

    test "broadcast performance with many subscribers" do
      manager_pid =
        case Process.whereis(Manager) do
          nil ->
            {:ok, pid} = Manager.start_link()
            pid

          pid ->
            pid
        end

      # Create subscriber processes
      subscribers =
        for _i <- 1..100 do
          spawn(fn ->
            receive do
              :stop -> :ok
            end
          end)
        end

      # Measure broadcast time
      message = {:test_broadcast, :performance_data, System.monotonic_time()}

      start_time = System.monotonic_time(:microsecond)

      # Simulate broadcasting to all subscribers
      Enum.each(subscribers, fn pid ->
        send(pid, message)
      end)

      end_time = System.monotonic_time(:microsecond)
      broadcast_time = (end_time - start_time) / 1000

      # Assert broadcast performance
      assert broadcast_time < 50, "Broadcast too slow: #{broadcast_time}ms for 100 subscribers"

      IO.puts("Broadcast time for 100 subscribers: #{Float.round(broadcast_time, 2)}ms")

      # Cleanup
      Enum.each(subscribers, &send(&1, :stop))
      if manager_pid && Process.alive?(manager_pid), do: GenServer.stop(manager_pid, :normal, 100)
    end
  end

  describe "stress testing" do
    @tag timeout: 60_000
    test "system remains stable under extreme load" do
      manager_pid =
        case Process.whereis(Manager) do
          nil ->
            {:ok, pid} = Manager.start_link()
            pid

          pid ->
            pid
        end

      # Generate extreme load
      # 5 seconds
      stress_duration = 5000
      end_time = System.monotonic_time(:millisecond) + stress_duration

      # Spawn multiple stress workers
      workers =
        for i <- 1..10 do
          Task.async(fn ->
            stress_worker(i, end_time)
          end)
        end

      # Wait for stress test to complete
      results = Task.await_many(workers, stress_duration + 5000)

      # Verify system is still operational
      assert Process.alive?(manager_pid)
      assert Manager.get_nodes() |> is_map()
      assert Manager.get_network_state() |> is_map()

      # Check results
      total_ops = Enum.sum(results)
      ops_per_second = total_ops / (stress_duration / 1000)

      IO.puts(
        "Stress test completed: #{total_ops} operations, #{Float.round(ops_per_second, 2)} ops/s"
      )

      assert total_ops > 1000, "Too few operations completed under stress"

      if manager_pid && Process.alive?(manager_pid), do: GenServer.stop(manager_pid, :normal, 100)
    end
  end

  # Helper function for stress testing
  defp stress_worker(worker_id, end_time) do
    stress_loop(worker_id, end_time, 0)
  end

  defp stress_loop(worker_id, end_time, count) do
    if System.monotonic_time(:millisecond) < end_time do
      # Random operations
      operation = Enum.random([:update, :read, :topology])

      case operation do
        :update ->
          node = :"stress_#{worker_id}_#{count}@localhost"
          Manager.update_node_status(node, Enum.random([:online, :offline, :connecting]))

        :read ->
          Manager.get_nodes()

        :topology ->
          Manager.get_network_state()
      end

      stress_loop(worker_id, end_time, count + 1)
    else
      count
    end
  end
end
