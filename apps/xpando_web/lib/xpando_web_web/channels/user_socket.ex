defmodule XpandoWebWeb.UserSocket do
  @moduledoc """
  UserSocket for Phoenix Channels with AshAuthentication integration.

  Handles authentication for P2P node communication channels using JWT tokens
  from the existing AshAuthentication system.
  """
  use Phoenix.Socket
  require Logger

  ## Channels
  channel "node:*", XpandoWebWeb.NodeChannel

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error` or `{:error, reason}`.
  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case verify_user_token(token) do
      {:ok, user} ->
        Logger.info("User #{user.email} authenticated for WebSocket connection")

        {:ok, assign(socket, :user, user)}

      {:error, reason} ->
        Logger.warning("WebSocket authentication failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @impl true
  def connect(_params, _socket, _connect_info) do
    Logger.warning("WebSocket connection attempted without token")
    {:error, :unauthorized}
  end

  # Socket ID is used to identify this client for PubSub purposes.
  # The socket ID should be unique for each user/device combination.
  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.user.id}"

  # Private Functions

  defp verify_user_token(token) do
    case AshAuthentication.Jwt.verify(token, XPando.Core.User) do
      {:ok, %{"sub" => subject}, _} ->
        # Load user by the subject (user ID) from the token
        case XPando.Core.User
             |> Ash.Query.for_read(:get_by_subject, %{subject: subject})
             |> Ash.read_one() do
          {:ok, user} -> {:ok, user}
          {:error, _} -> {:error, :user_not_found}
          nil -> {:error, :user_not_found}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
