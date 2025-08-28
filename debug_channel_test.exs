# Debug script to understand channel test failures
ExUnit.start()

defmodule DebugChannelTest do
  use ExUnit.Case
  import Phoenix.ChannelTest

  @endpoint XpandoWebWeb.Endpoint

  test "debug channel joining" do
    # Create a test user
    user = %{
      id: "test-user-id",
      email: "test@example.com",
      role: :node_operator,
      node_id: nil
    }

    # Connect to socket
    {:ok, socket} = socket_connect(XpandoWebWeb.UserSocket, %{}, %{user: user})

    IO.puts("Socket after connection:")
    IO.inspect(socket)

    # Try to join - debug what happens
    IO.puts("Attempting to join node:network...")

    try do
      result = subscribe_and_join(socket, XpandoWebWeb.NodeChannel, "node:network")
      IO.puts("subscribe_and_join result:")
      IO.inspect(result)
    rescue
      error ->
        IO.puts("Error in subscribe_and_join:")
        IO.inspect(error)
        IO.puts("Stacktrace:")
        IO.inspect(__STACKTRACE__)
    end
  end

  defp socket_connect(socket_module, _params \\ %{}, assigns \\ %{}) do
    # Create a mock socket with the provided assigns
    socket = %Phoenix.Socket{
      assigns: Map.merge(%{user: nil}, assigns),
      endpoint: XpandoWebWeb.Endpoint,
      handler: socket_module,
      id: nil,
      joined: false,
      ref: nil,
      topic: nil,
      transport: Phoenix.ChannelTest.NoopTransport,
      transport_pid: self()
    }

    {:ok, socket}
  end
end
