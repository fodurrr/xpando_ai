defmodule SimpleTestChannel do
  use Phoenix.Channel

  def join("simple:test", _payload, socket) do
    {:ok, %{message: "joined successfully"}, socket}
  end

  def join(_topic, _payload, _socket) do
    {:error, %{reason: "invalid_topic"}}
  end
end
