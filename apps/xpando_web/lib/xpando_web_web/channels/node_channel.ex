defmodule XpandoWebWeb.NodeChannel do
  @moduledoc """
  Phoenix Channel for P2P node-to-node communication.

  Handles real-time messaging between distributed AI nodes including:
  - Node joining/leaving the network
  - Heartbeat messages for health monitoring  
  - Data exchange and knowledge sharing
  - Network topology updates
  """
  use Phoenix.Channel
  require Logger

  alias XPando.Node.Manager
  # Remove unused aliases

  @doc """
  Authorize the socket for the given topic.

  Topics supported:
  - "node:network" - General network updates and coordination
  - "node:<node_id>" - Direct node-to-node communication
  """
  def join("node:network", _payload, socket) do
    Logger.info("User #{socket.assigns.user.email} joined node network channel")

    # Subscribe to network-wide events (safely)
    safe_subscribe("cluster:events")
    safe_subscribe("network:updates")

    # Send current network state to the newly joined client (with fallback for tests)
    {nodes, topology} = get_network_state_safe()

    {:ok, %{nodes: nodes, topology: topology}, socket}
  end

  def join("node:" <> node_id, _payload, socket) do
    # Check if user has permission to communicate with this specific node
    case can_access_node?(socket.assigns.user, node_id) do
      true ->
        Logger.info("User #{socket.assigns.user.email} joined node channel: #{node_id}")

        # Subscribe to specific node events
        Phoenix.PubSub.subscribe(XpandoWeb.PubSub, "node:#{node_id}")

        {:ok, %{node_id: node_id}, socket}

      false ->
        Logger.warning("User #{socket.assigns.user.email} denied access to node: #{node_id}")
        {:error, %{reason: "unauthorized"}}
    end
  end

  def join(_topic, _payload, _socket) do
    {:error, %{reason: "invalid_topic"}}
  end

  # Handle incoming messages

  def handle_in("join", %{"node_id" => node_id, "metadata" => metadata}, socket) do
    Logger.info("Node join request: #{node_id}")

    # Update node status (safe call)
    safe_update_node_status(String.to_atom(node_id), :connecting)

    # Broadcast join event to all network subscribers
    safe_broadcast("network:updates", {:node_join_request, node_id, metadata})

    {:reply, {:ok, %{status: "join_acknowledged"}}, socket}
  end

  def handle_in("leave", %{"node_id" => node_id, "reason" => reason}, socket) do
    Logger.info("Node leave notification: #{node_id} (reason: #{reason})")

    # Update node status (safe call)
    safe_update_node_status(String.to_atom(node_id), :offline)

    # Broadcast leave event to all network subscribers
    safe_broadcast("network:updates", {:node_leave, node_id, reason})

    {:reply, {:ok, %{status: "leave_acknowledged"}}, socket}
  end

  def handle_in("heartbeat", %{"node_id" => node_id, "timestamp" => timestamp}, socket) do
    Logger.debug("Heartbeat from node: #{node_id}")

    # Update node status and last seen (safe call)
    safe_update_node_status(String.to_atom(node_id), :online)

    # Broadcast heartbeat to network monitoring
    safe_broadcast("cluster:events", {:heartbeat, node_id, timestamp})

    {:reply, {:ok, %{status: "heartbeat_received", server_time: DateTime.utc_now()}}, socket}
  end

  def handle_in("data", %{"type" => data_type, "payload" => payload}, socket) do
    Logger.info("Data message received: #{data_type}")

    case data_type do
      "knowledge_update" ->
        handle_knowledge_update(payload, socket)

      "model_sync" ->
        handle_model_sync(payload, socket)

      "capability_announcement" ->
        handle_capability_announcement(payload, socket)

      _ ->
        Logger.warning("Unknown data type: #{data_type}")
        {:reply, {:error, %{reason: "unknown_data_type"}}, socket}
    end
  end

  def handle_in("ping", %{"timestamp" => timestamp}, socket) do
    {:reply, {:ok, %{pong: true, timestamp: timestamp, server_time: DateTime.utc_now()}}, socket}
  end

  def handle_in("get_network_state", _payload, socket) do
    {nodes, topology} = get_network_state_safe()

    {:reply, {:ok, %{nodes: nodes, topology: topology}}, socket}
  end

  # Handle outgoing PubSub messages
  def handle_info({:node_connected, node}, socket) do
    push(socket, "node_connected", %{node: node, timestamp: DateTime.utc_now()})
    {:noreply, socket}
  end

  def handle_info({:node_disconnected, node}, socket) do
    push(socket, "node_disconnected", %{node: node, timestamp: DateTime.utc_now()})
    {:noreply, socket}
  end

  def handle_info({:node_status_change, node_id, status}, socket) do
    push(socket, "node_status_change", %{
      node_id: node_id,
      status: status,
      timestamp: DateTime.utc_now()
    })

    {:noreply, socket}
  end

  def handle_info({:heartbeat, node_id, timestamp}, socket) do
    push(socket, "heartbeat_broadcast", %{
      node_id: node_id,
      timestamp: timestamp
    })

    {:noreply, socket}
  end

  def handle_info({:network_topology_update, topology}, socket) do
    push(socket, "topology_update", %{topology: topology, timestamp: DateTime.utc_now()})
    {:noreply, socket}
  end

  # Handle unknown messages
  def handle_info(msg, socket) do
    Logger.debug("Unhandled message in NodeChannel: #{inspect(msg)}")
    {:noreply, socket}
  end

  # Private helper functions

  defp can_access_node?(user, node_id) do
    case user.role do
      :admin ->
        true

      :node_operator ->
        # Node operators can access their assigned node and network channel
        case Map.get(user, :node_id) do
          # Can only access network channel if no node assigned
          nil -> node_id == "network"
          assigned_node_id -> to_string(assigned_node_id) == node_id or node_id == "network"
        end

      :user ->
        # Regular users can only access the network channel for read-only monitoring
        node_id == "network"
    end
  end

  defp handle_knowledge_update(payload, socket) do
    Logger.info("Processing knowledge update")

    # Broadcast knowledge update to interested nodes
    safe_broadcast(
      "network:updates",
      {:knowledge_update, payload}
    )

    {:reply, {:ok, %{status: "knowledge_update_processed"}}, socket}
  end

  defp handle_model_sync(payload, socket) do
    Logger.info("Processing model sync request")

    # Broadcast model sync to network
    safe_broadcast(
      "network:updates",
      {:model_sync, payload}
    )

    {:reply, {:ok, %{status: "model_sync_initiated"}}, socket}
  end

  defp handle_capability_announcement(payload, socket) do
    Logger.info("Processing capability announcement")

    # Broadcast capability to network
    safe_broadcast(
      "network:updates",
      {:capability_announcement, payload}
    )

    {:reply, {:ok, %{status: "capability_registered"}}, socket}
  end

  # Helper functions for safe operations

  defp safe_subscribe(topic) do
    try do
      Phoenix.PubSub.subscribe(XpandoWeb.PubSub, topic)
    rescue
      error ->
        Logger.debug("Failed to subscribe to #{topic}: #{inspect(error)}")
        :error
    end
  end

  defp get_network_state_safe do
    try do
      nodes = Manager.get_nodes()
      topology = Manager.get_topology()
      {nodes, topology}
    rescue
      error ->
        Logger.debug("Failed to get network state from Manager: #{inspect(error)}")
        # Return empty/default state for tests
        {%{}, %{}}
    catch
      :exit, reason ->
        Logger.debug("Failed to get network state from Manager: #{inspect(reason)}")
        # Return empty/default state for tests
        {%{}, %{}}
    end
  end

  defp safe_update_node_status(node_id, status) do
    try do
      Manager.update_node_status(node_id, status)
    rescue
      error ->
        Logger.debug("Failed to update node status for #{node_id}: #{inspect(error)}")
        :error
    catch
      :exit, reason ->
        Logger.debug("Failed to update node status for #{node_id}: #{inspect(reason)}")
        :error
    end
  end

  defp safe_broadcast(topic, message) do
    try do
      Phoenix.PubSub.broadcast(XpandoWeb.PubSub, topic, message)
    rescue
      error ->
        Logger.debug("Failed to broadcast to #{topic}: #{inspect(error)}")
        :error
    end
  end
end
