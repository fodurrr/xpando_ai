defmodule XPando.Node.Manager do
  @moduledoc """
  GenServer-based node management system for P2P network functionality.

  Handles:
  - Node status tracking (online/offline/connecting states)
  - Network topology management
  - Periodic heartbeat system for health monitoring
  - Connection health monitoring and automatic reconnection
  """
  use GenServer
  require Logger

  @heartbeat_interval :timer.seconds(30)
  @reconnect_backoff_base :timer.seconds(5)
  @max_reconnect_attempts 5
  @connection_timeout :timer.seconds(10)
  @health_check_interval :timer.seconds(15)

  # Client API

  @doc """
  Starts the Node Manager GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets the current state of all nodes in the network.
  """
  def get_nodes do
    GenServer.call(__MODULE__, :get_nodes)
  end

  @doc """
  Gets the network topology showing which nodes are connected to which.
  """
  def get_topology do
    GenServer.call(__MODULE__, :get_topology)
  end

  @doc """
  Updates the status of a specific node.
  """
  def update_node_status(node_id, status) when status in [:online, :offline, :connecting] do
    GenServer.cast(__MODULE__, {:update_node_status, node_id, status})
  end

  @doc """
  Triggers a heartbeat check for all nodes.
  """
  def trigger_heartbeat do
    GenServer.cast(__MODULE__, :trigger_heartbeat)
  end

  @doc """
  Gets connection health statistics for monitoring.
  """
  def get_health_stats do
    GenServer.call(__MODULE__, :get_health_stats)
  end

  @doc """
  Gets detailed network topology information including connection graph.
  """
  def get_network_topology do
    GenServer.call(__MODULE__, :get_network_topology)
  end

  @doc """
  Gets the full network state including nodes, topology, and health metrics.
  """
  def get_network_state do
    GenServer.call(__MODULE__, :get_network_state)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    Logger.info("Node Manager starting - Enhanced health monitoring enabled")

    # Schedule periodic heartbeat and health checks
    schedule_heartbeat()
    schedule_health_check()

    # Subscribe to cluster events (if PubSub is available)
    case Process.whereis(XpandoWeb.PubSub) do
      nil ->
        Logger.debug("PubSub server not available, skipping cluster events subscription")

      _pid ->
        try do
          Phoenix.PubSub.subscribe(XpandoWeb.PubSub, "cluster:events")
          Logger.debug("Successfully subscribed to cluster events")
        rescue
          error ->
            Logger.warning("Failed to subscribe to cluster events: #{inspect(error)}")
        end
    end

    # Monitor node connections/disconnections with detailed reasons
    :ok = :net_kernel.monitor_nodes(true, [:nodedown_reason, :connection_id])

    initial_state = %{
      nodes: %{},
      topology: %{
        connections: %{},
        network_map: %{},
        last_topology_update: DateTime.utc_now()
      },
      heartbeat_failures: %{},
      connection_stats: %{
        total_connections: 0,
        failed_connections: 0,
        reconnection_attempts: 0,
        last_health_check: DateTime.utc_now(),
        uptime_start: DateTime.utc_now()
      }
    }

    {:ok, initial_state, {:continue, :connect_cluster}}
  end

  @impl true
  def handle_continue(:connect_cluster, state) do
    Logger.info("Connecting to cluster...")

    # Get current cluster nodes
    current_node = node()
    cluster_nodes = [current_node | :erlang.nodes()]
    Logger.info("Cluster nodes: #{inspect(cluster_nodes)}")

    # Initialize node tracking for all cluster nodes
    nodes =
      cluster_nodes
      |> Enum.reduce(%{}, fn cluster_node, acc ->
        Map.put(acc, cluster_node, %{
          status: if(cluster_node == current_node, do: :online, else: :connecting),
          last_heartbeat: DateTime.utc_now(),
          reconnect_attempts: 0
        })
      end)

    # Broadcast that we're online
    safe_broadcast("cluster:events", {:node_online, current_node})

    {:noreply, %{state | nodes: nodes}}
  end

  @impl true
  def handle_call(:get_nodes, _from, state) do
    {:reply, state.nodes, state}
  end

  @impl true
  def handle_call(:get_topology, _from, state) do
    {:reply, state.topology, state}
  end

  @impl true
  def handle_call(:get_health_stats, _from, state) do
    current_time = DateTime.utc_now()
    uptime_seconds = DateTime.diff(current_time, state.connection_stats.uptime_start, :second)

    health_stats =
      Map.merge(state.connection_stats, %{
        current_time: current_time,
        uptime_seconds: uptime_seconds,
        active_nodes: Enum.count(state.nodes, fn {_node, data} -> data.status == :online end),
        total_nodes: map_size(state.nodes),
        topology_connections: map_size(state.topology)
      })

    {:reply, health_stats, state}
  end

  @impl true
  def handle_call(:get_network_topology, _from, state) do
    {:reply, state.topology, state}
  end

  @impl true
  def handle_call(:get_network_state, _from, state) do
    current_time = DateTime.utc_now()

    network_state = %{
      timestamp: current_time,
      current_node: node(),
      nodes: state.nodes,
      topology: state.topology,
      connection_stats: state.connection_stats,
      cluster_nodes: :erlang.nodes(),
      network_health: calculate_network_health(state)
    }

    {:reply, network_state, state}
  end

  @impl true
  def handle_cast({:update_node_status, node_id, status}, state) do
    Logger.debug("Updating node #{node_id} status to #{status}")

    updated_nodes =
      Map.update(
        state.nodes,
        node_id,
        %{
          status: status,
          last_heartbeat: DateTime.utc_now(),
          reconnect_attempts: 0
        },
        fn node_data ->
          %{
            node_data
            | status: status,
              last_heartbeat: DateTime.utc_now(),
              reconnect_attempts: if(status == :online, do: 0, else: node_data.reconnect_attempts)
          }
        end
      )

    # Broadcast status change
    safe_broadcast("cluster:events", {:node_status_change, node_id, status})

    {:noreply, %{state | nodes: updated_nodes}}
  end

  @impl true
  def handle_cast(:trigger_heartbeat, state) do
    new_state = perform_heartbeat_check(state)
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:heartbeat, state) do
    new_state = perform_heartbeat_check(state)
    schedule_heartbeat()
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:health_check, state) do
    Logger.debug("Performing comprehensive health check")
    new_state = perform_comprehensive_health_check(state)
    schedule_health_check()
    {:noreply, new_state}
  end

  @impl true
  def handle_info({:nodeup, node}, state) do
    connection_time = DateTime.utc_now()
    Logger.info("Node connected: #{node} at #{DateTime.to_iso8601(connection_time)}")

    updated_nodes =
      Map.put(state.nodes, node, %{
        status: :online,
        last_heartbeat: connection_time,
        reconnect_attempts: 0,
        connected_at: connection_time,
        connection_history: [
          connection_time | Map.get(state.nodes, node, %{}) |> Map.get(:connection_history, [])
        ]
      })

    # Update topology
    updated_topology = update_topology(state.topology, node, :connected)

    # Update connection stats
    updated_stats = %{
      state.connection_stats
      | total_connections: state.connection_stats.total_connections + 1,
        last_health_check: connection_time
    }

    # Broadcast node connection with timestamp and topology info
    safe_broadcast("cluster:events", {
      :node_connected,
      node,
      %{timestamp: connection_time, connection_count: updated_stats.total_connections}
    })

    # Broadcast topology update
    safe_broadcast("network:topology", {
      :topology_updated,
      %{
        action: :node_connected,
        node: node,
        timestamp: connection_time,
        topology_summary: %{
          total_connections: map_size(updated_topology.connections) / 2,
          network_nodes: MapSet.size(MapSet.new(Map.keys(updated_topology.network_map))),
          last_update: updated_topology.last_topology_update
        }
      }
    })

    {:noreply,
     %{state | nodes: updated_nodes, topology: updated_topology, connection_stats: updated_stats}}
  end

  @impl true
  def handle_info({:nodedown, node, reason}, state) do
    disconnection_time = DateTime.utc_now()

    Logger.warning(
      "Node disconnected: #{node} at #{DateTime.to_iso8601(disconnection_time)} - Reason: #{inspect(reason)}"
    )

    # Calculate connection duration if we have connected_at
    connection_duration =
      case Map.get(state.nodes, node) do
        %{connected_at: connected_at} ->
          DateTime.diff(disconnection_time, connected_at, :second)

        _ ->
          nil
      end

    updated_nodes =
      Map.update(
        state.nodes,
        node,
        %{
          status: :offline,
          last_heartbeat: disconnection_time,
          reconnect_attempts: 0,
          disconnected_at: disconnection_time,
          last_disconnect_reason: reason
        },
        fn node_data ->
          node_data
          |> Map.put(:status, :offline)
          |> Map.put(:last_heartbeat, disconnection_time)
          |> Map.put(:disconnected_at, disconnection_time)
          |> Map.put(:last_disconnect_reason, reason)
          |> maybe_add_connection_duration(connection_duration)
        end
      )

    # Update topology
    updated_topology = update_topology(state.topology, node, :disconnected)

    # Update failure stats
    updated_stats = %{
      state.connection_stats
      | failed_connections: state.connection_stats.failed_connections + 1
    }

    # Broadcast node disconnection with details
    safe_broadcast("cluster:events", {
      :node_disconnected,
      node,
      %{
        timestamp: disconnection_time,
        reason: reason,
        connection_duration: connection_duration,
        failure_count: updated_stats.failed_connections
      }
    })

    # Broadcast topology update
    safe_broadcast("network:topology", {
      :topology_updated,
      %{
        action: :node_disconnected,
        node: node,
        timestamp: disconnection_time,
        reason: reason,
        topology_summary: %{
          total_connections: map_size(updated_topology.connections) / 2,
          network_nodes: MapSet.size(MapSet.new(Map.keys(updated_topology.network_map))),
          last_update: updated_topology.last_topology_update
        }
      }
    })

    # Schedule reconnection attempt with timeout protection
    schedule_reconnection_with_timeout(node, 1)

    {:noreply,
     %{state | nodes: updated_nodes, topology: updated_topology, connection_stats: updated_stats}}
  end

  # Handle legacy nodedown messages without reason
  @impl true
  def handle_info({:nodedown, node}, state) do
    handle_info({:nodedown, node, :unknown_reason}, state)
  end

  @impl true
  def handle_info({:reconnect, node, attempt}, state) do
    case Map.get(state.nodes, node) do
      %{status: :offline, reconnect_attempts: attempts} when attempts < @max_reconnect_attempts ->
        reconnect_time = DateTime.utc_now()

        Logger.info(
          "Attempting to reconnect to #{node} (attempt #{attempt}/#{@max_reconnect_attempts}) at #{DateTime.to_iso8601(reconnect_time)}"
        )

        # Update stats for reconnection attempt
        updated_stats = %{
          state.connection_stats
          | reconnection_attempts: state.connection_stats.reconnection_attempts + 1
        }

        # Use Task to handle connection with timeout
        task =
          Task.async(fn ->
            Process.flag(:trap_exit, true)
            :net_kernel.connect_node(node)
          end)

        case Task.yield(task, @connection_timeout) do
          {:ok, true} ->
            Logger.info("Successfully reconnected to #{node} after #{attempt} attempts")

            updated_nodes = update_node_on_reconnect(state.nodes, node, reconnect_time)

            safe_broadcast("cluster:events", {
              :node_reconnected,
              node,
              %{timestamp: reconnect_time, attempt: attempt}
            })

            {:noreply, %{state | nodes: updated_nodes, connection_stats: updated_stats}}

          {:ok, false} ->
            Logger.warning(
              "Failed to reconnect to #{node} (attempt #{attempt}) - Connection refused"
            )

            handle_failed_reconnection(state, node, attempt, :connection_refused, updated_stats)

          nil ->
            # Timeout occurred
            Task.shutdown(task, :brutal_kill)

            Logger.warning(
              "Reconnection to #{node} timed out after #{@connection_timeout}ms (attempt #{attempt})"
            )

            handle_failed_reconnection(state, node, attempt, :timeout, updated_stats)

          {:exit, reason} ->
            Logger.error(
              "Reconnection to #{node} failed with error: #{inspect(reason)} (attempt #{attempt})"
            )

            handle_failed_reconnection(state, node, attempt, reason, updated_stats)
        end

      _ ->
        # Node is already connected or max attempts reached
        Logger.debug(
          "Skipping reconnection to #{node} - node status changed or max attempts reached"
        )

        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:node_online, node}, state) do
    Logger.debug("Received node online broadcast from #{node}")

    updated_nodes =
      Map.put(state.nodes, node, %{
        status: :online,
        last_heartbeat: DateTime.utc_now(),
        reconnect_attempts: 0
      })

    {:noreply, %{state | nodes: updated_nodes}}
  end

  @impl true
  def handle_info({:node_status_change, node_id, status}, state) do
    Logger.debug("Received status change broadcast: #{node_id} -> #{status}")
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # Private Functions

  defp schedule_heartbeat do
    Process.send_after(self(), :heartbeat, @heartbeat_interval)
  end

  defp schedule_health_check do
    Process.send_after(self(), :health_check, @health_check_interval)
  end

  defp handle_failed_reconnection(state, node, attempt, reason, updated_stats) do
    updated_nodes =
      Map.update(state.nodes, node, %{}, fn node_data ->
        %{node_data | reconnect_attempts: attempt, last_reconnection_error: reason}
      end)

    # Schedule next reconnection with exponential backoff or give up
    if attempt < @max_reconnect_attempts do
      schedule_reconnection_with_timeout(node, attempt + 1)
    else
      Logger.error("Max reconnection attempts (#{@max_reconnect_attempts}) reached for #{node}")

      safe_broadcast("cluster:events", {
        :node_reconnection_failed,
        node,
        %{final_attempt: attempt, reason: reason}
      })
    end

    {:noreply, %{state | nodes: updated_nodes, connection_stats: updated_stats}}
  end

  defp schedule_reconnection_with_timeout(node, attempt) do
    backoff = (@reconnect_backoff_base * :math.pow(2, attempt - 1)) |> round()
    Logger.debug("Scheduling reconnection to #{node} in #{backoff}ms (attempt #{attempt})")
    Process.send_after(self(), {:reconnect, node, attempt}, backoff)
  end

  # Helper function to safely broadcast to PubSub (handles cases where PubSub might not be available)
  defp safe_broadcast(topic, message) do
    Phoenix.PubSub.broadcast(XpandoWeb.PubSub, topic, message)
  rescue
    error ->
      Logger.debug("Failed to broadcast to #{topic}: #{inspect(error)}")
      :error
  end

  defp perform_heartbeat_check(state) do
    Logger.debug("Performing heartbeat check")
    current_time = DateTime.utc_now()

    # Check for stale nodes (no heartbeat in last 2 minutes)
    stale_threshold = DateTime.add(current_time, -120, :second)

    updated_nodes =
      state.nodes
      |> Enum.reduce(%{}, fn {node, node_data}, acc ->
        if DateTime.compare(node_data.last_heartbeat, stale_threshold) == :lt and
             node_data.status == :online and
             node != Node.self() do
          Logger.warning("Node #{node} appears stale, marking as connecting")
          Map.put(acc, node, %{node_data | status: :connecting})
        else
          Map.put(acc, node, node_data)
        end
      end)

    # Broadcast heartbeat
    safe_broadcast("cluster:events", {:heartbeat, node()})

    %{state | nodes: updated_nodes}
  end

  defp perform_comprehensive_health_check(state) do
    current_time = DateTime.utc_now()

    # Check for nodes that might need intervention
    {healthy_nodes, problematic_nodes} =
      state.nodes
      |> Enum.split_with(fn {_node, data} ->
        case data.status do
          :online -> true
          :connecting -> DateTime.diff(current_time, data.last_heartbeat, :second) < 60
          :offline -> data.reconnect_attempts < @max_reconnect_attempts
        end
      end)

    # Log health summary
    Logger.info(
      "Health Check Summary: #{length(healthy_nodes)} healthy, #{length(problematic_nodes)} problematic nodes"
    )

    # Log details about problematic nodes
    Enum.each(problematic_nodes, fn {node, data} ->
      Logger.warning(
        "Problematic node #{node}: status=#{data.status}, attempts=#{data.reconnect_attempts}, last_heartbeat=#{DateTime.to_iso8601(data.last_heartbeat)}"
      )
    end)

    # Update connection stats with health check timestamp
    updated_stats = %{state.connection_stats | last_health_check: current_time}

    # Broadcast health status
    health_summary = %{
      timestamp: current_time,
      healthy_count: length(healthy_nodes),
      problematic_count: length(problematic_nodes),
      total_nodes: map_size(state.nodes)
    }

    safe_broadcast("cluster:events", {:health_check, health_summary})

    # Also broadcast current topology state
    safe_broadcast("network:topology", {
      :topology_snapshot,
      %{
        timestamp: current_time,
        connections: state.topology.connections,
        network_map: state.topology.network_map,
        health_summary: health_summary
      }
    })

    %{state | connection_stats: updated_stats}
  end

  defp update_topology(topology, node, action) do
    current_node = node()
    current_time = DateTime.utc_now()

    case action do
      :connected ->
        # Update direct connections
        updated_connections =
          topology.connections
          |> Map.put({current_node, node}, %{
            established_at: current_time,
            last_seen: current_time,
            status: :active
          })
          |> Map.put({node, current_node}, %{
            established_at: current_time,
            last_seen: current_time,
            status: :active
          })

        # Update network map - track which nodes this node can reach
        updated_network_map =
          topology.network_map
          |> Map.update(current_node, MapSet.new([node]), fn connections ->
            MapSet.put(connections, node)
          end)
          |> Map.update(node, MapSet.new([current_node]), fn connections ->
            MapSet.put(connections, current_node)
          end)

        %{
          topology
          | connections: updated_connections,
            network_map: updated_network_map,
            last_topology_update: current_time
        }

      :disconnected ->
        # Remove direct connections
        updated_connections =
          topology.connections
          |> Map.delete({current_node, node})
          |> Map.delete({node, current_node})

        # Update network map - remove disconnected nodes
        updated_network_map =
          topology.network_map
          |> Map.update(current_node, MapSet.new(), fn connections ->
            MapSet.delete(connections, node)
          end)
          |> Map.update(node, MapSet.new(), fn connections ->
            MapSet.delete(connections, current_node)
          end)

        %{
          topology
          | connections: updated_connections,
            network_map: updated_network_map,
            last_topology_update: current_time
        }
    end
  end

  defp calculate_network_health(state) do
    total_nodes = map_size(state.nodes)
    online_nodes = Enum.count(state.nodes, fn {_node, data} -> data.status == :online end)

    health_percentage =
      if total_nodes > 0 do
        online_nodes / total_nodes * 100
      else
        100.0
      end

    %{
      total_nodes: total_nodes,
      online_nodes: online_nodes,
      offline_nodes: total_nodes - online_nodes,
      health_percentage: Float.round(health_percentage, 1),
      network_partitioned: online_nodes > 0 && online_nodes < total_nodes,
      # Divide by 2 because connections are bidirectional
      topology_connections: map_size(state.topology.connections) / 2
    }
  end

  # Helper functions to reduce nesting
  defp maybe_add_connection_duration(data, nil), do: data

  defp maybe_add_connection_duration(data, connection_duration) do
    Map.put(data, :connection_duration, connection_duration)
  end

  defp update_node_on_reconnect(nodes, node, reconnect_time) do
    Map.update(nodes, node, %{}, fn node_data ->
      %{
        node_data
        | status: :connecting,
          last_heartbeat: reconnect_time,
          reconnect_attempts: 0,
          last_successful_reconnect: reconnect_time
      }
    end)
  end
end
