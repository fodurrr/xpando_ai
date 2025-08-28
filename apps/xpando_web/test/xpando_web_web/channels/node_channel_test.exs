defmodule XpandoWebWeb.NodeChannelTest do
  use XpandoWebWeb.ChannelCase, async: false

  alias XpandoWebWeb.{NodeChannel, UserSocket}

  setup do
    # Create a test user for authentication
    user = %{
      id: "test-user-id",
      email: "test@example.com",
      role: :node_operator,
      node_id: nil
    }

    # Create socket using Phoenix.ChannelTest socket/4 function
    socket = socket(UserSocket, "user_socket:#{user.id}", %{user: user})

    %{socket: socket, user: user}
  end

  describe "joining channels" do
    test "can join node:network channel", %{socket: socket} do
      # Test the channel join directly
      case NodeChannel.join("node:network", %{}, socket) do
        {:ok, reply, joined_socket} ->
          assert Map.has_key?(reply, :nodes)
          assert Map.has_key?(reply, :topology)
          assert joined_socket.assigns.user.email == "test@example.com"

        error ->
          flunk("Expected successful join, got: #{inspect(error)}")
      end
    end

    test "can join specific node channel with proper permissions", %{socket: socket} do
      # Node operator with no assigned node_id cannot access specific nodes
      case NodeChannel.join("node:test-node", %{}, socket) do
        {:error, %{reason: "unauthorized"}} ->
          # This is the expected behavior for node_operator with node_id: nil
          assert true

        other ->
          flunk("Expected unauthorized error, got: #{inspect(other)}")
      end
    end

    test "rejects invalid topics", %{socket: socket} do
      case NodeChannel.join("invalid:topic", %{}, socket) do
        {:error, %{reason: "invalid_topic"}} ->
          assert true

        other ->
          flunk("Expected invalid_topic error, got: #{inspect(other)}")
      end
    end

    test "rejects unauthorized node access for regular users" do
      user = %{id: "user-id", email: "user@example.com", role: :user, node_id: nil}

      socket = socket(UserSocket, "user_socket:#{user.id}", %{user: user})

      case NodeChannel.join("node:some-node", %{}, socket) do
        {:error, %{reason: "unauthorized"}} ->
          assert true

        other ->
          flunk("Expected unauthorized error, got: #{inspect(other)}")
      end
    end
  end

  describe "handling incoming messages" do
    setup %{socket: socket} do
      # Use subscribe_and_join properly
      {:ok, _, socket} = subscribe_and_join(socket, NodeChannel, "node:network")
      %{socket: socket}
    end

    test "handles join messages", %{socket: socket} do
      ref =
        push(socket, "join", %{
          "node_id" => "new-node",
          "metadata" => %{"version" => "1.0"}
        })

      assert_reply ref, :ok, %{status: "join_acknowledged"}
      # The channel doesn't push back join events to the same socket
    end

    test "handles leave messages", %{socket: socket} do
      ref =
        push(socket, "leave", %{
          "node_id" => "departing-node",
          "reason" => "shutdown"
        })

      assert_reply ref, :ok, %{status: "leave_acknowledged"}
      # The channel doesn't push back leave events to the same socket
    end

    test "handles heartbeat messages", %{socket: socket} do
      timestamp = DateTime.utc_now() |> DateTime.to_iso8601()

      ref =
        push(socket, "heartbeat", %{
          "node_id" => "active-node",
          "timestamp" => timestamp
        })

      assert_reply ref, :ok, %{status: "heartbeat_received", server_time: _}
      # The channel doesn't push back heartbeat events to the same socket
    end

    test "handles data messages with knowledge_update type", %{socket: socket} do
      ref =
        push(socket, "data", %{
          "type" => "knowledge_update",
          "payload" => %{"knowledge_id" => "123", "content" => "test knowledge"}
        })

      assert_reply ref, :ok, %{status: "knowledge_update_processed"}
      # The channel doesn't broadcast back to the socket for data messages
      # It broadcasts to the PubSub topic "network:updates" instead
    end

    test "handles data messages with model_sync type", %{socket: socket} do
      ref =
        push(socket, "data", %{
          "type" => "model_sync",
          "payload" => %{"model_id" => "456", "weights" => "binary_data"}
        })

      assert_reply ref, :ok, %{status: "model_sync_initiated"}
      # The channel doesn't broadcast back to the socket for data messages
      # It broadcasts to the PubSub topic "network:updates" instead
    end

    test "handles data messages with capability_announcement type", %{socket: socket} do
      ref =
        push(socket, "data", %{
          "type" => "capability_announcement",
          "payload" => %{"capabilities" => ["text_generation", "image_analysis"]}
        })

      assert_reply ref, :ok, %{status: "capability_registered"}
      # The channel doesn't broadcast back to the socket for data messages
      # It broadcasts to the PubSub topic "network:updates" instead
    end

    test "rejects unknown data types", %{socket: socket} do
      ref =
        push(socket, "data", %{
          "type" => "unknown_type",
          "payload" => %{"data" => "test"}
        })

      assert_reply ref, :error, %{reason: "unknown_data_type"}
    end

    test "handles ping messages", %{socket: socket} do
      timestamp = DateTime.utc_now() |> DateTime.to_iso8601()

      ref = push(socket, "ping", %{"timestamp" => timestamp})

      assert_reply ref, :ok, %{pong: true, timestamp: ^timestamp, server_time: _}
    end

    test "handles get_network_state messages", %{socket: socket} do
      ref = push(socket, "get_network_state", %{})

      assert_reply ref, :ok, %{nodes: _, topology: _}
    end
  end

  describe "handling outgoing messages" do
    setup %{socket: socket} do
      {:ok, _, socket} = subscribe_and_join(socket, NodeChannel, "node:network")
      %{socket: socket}
    end

    test "pushes node_connected events", %{socket: socket} do
      send(socket.channel_pid, {:node_connected, :test@node})

      assert_push "node_connected", %{node: :test@node, timestamp: _}
    end

    test "pushes node_disconnected events", %{socket: socket} do
      send(socket.channel_pid, {:node_disconnected, :test@node})

      assert_push "node_disconnected", %{node: :test@node, timestamp: _}
    end

    test "pushes node_status_change events", %{socket: socket} do
      send(socket.channel_pid, {:node_status_change, "test-node", :online})

      assert_push "node_status_change", %{
        node_id: "test-node",
        status: :online,
        timestamp: _
      }
    end

    test "pushes heartbeat_broadcast events", %{socket: socket} do
      timestamp = DateTime.utc_now()
      send(socket.channel_pid, {:heartbeat, "test-node", timestamp})

      assert_push "heartbeat_broadcast", %{
        node_id: "test-node",
        timestamp: ^timestamp
      }
    end

    test "pushes topology_update events", %{socket: socket} do
      topology = %{"node1" => ["node2", "node3"]}
      send(socket.channel_pid, {:network_topology_update, topology})

      assert_push "topology_update", %{topology: ^topology, timestamp: _}
    end

    test "handles unknown info messages gracefully", %{socket: socket} do
      send(socket.channel_pid, {:unknown_message, "data"})

      # Should not crash and should not push anything
      refute_push _event, _payload
    end
  end

  describe "authorization" do
    test "admin users can access any node channel" do
      user = %{id: "admin-id", email: "admin@example.com", role: :admin, node_id: nil}

      socket = socket(UserSocket, "user_socket:#{user.id}", %{user: user})

      case NodeChannel.join("node:any-node", %{}, socket) do
        {:ok, reply, _socket} ->
          assert reply.node_id == "any-node"

        error ->
          flunk("Expected admin to join any node, got: #{inspect(error)}")
      end
    end

    test "node operators can access their assigned node" do
      user = %{
        id: "op-id",
        email: "op@example.com",
        role: :node_operator,
        node_id: "assigned-node"
      }

      socket = socket(UserSocket, "user_socket:#{user.id}", %{user: user})

      case NodeChannel.join("node:assigned-node", %{}, socket) do
        {:ok, reply, _socket} ->
          assert reply.node_id == "assigned-node"

        error ->
          flunk("Expected node operator to join assigned node, got: #{inspect(error)}")
      end
    end

    test "node operators cannot access other nodes" do
      user = %{
        id: "op-id",
        email: "op@example.com",
        role: :node_operator,
        node_id: "assigned-node"
      }

      socket = socket(UserSocket, "user_socket:#{user.id}", %{user: user})

      case NodeChannel.join("node:other-node", %{}, socket) do
        {:error, %{reason: "unauthorized"}} ->
          assert true

        other ->
          flunk("Expected unauthorized error, got: #{inspect(other)}")
      end
    end

    test "regular users can only access network channel" do
      user = %{id: "user-id", email: "user@example.com", role: :user, node_id: nil}

      socket = socket(UserSocket, "user_socket:#{user.id}", %{user: user})

      case NodeChannel.join("node:network", %{}, socket) do
        {:ok, reply, _socket} ->
          assert Map.has_key?(reply, :nodes)
          assert Map.has_key?(reply, :topology)

        error ->
          flunk("Expected regular user to join network channel, got: #{inspect(error)}")
      end
    end
  end
end
