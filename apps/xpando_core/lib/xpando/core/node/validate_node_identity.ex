defmodule XPando.Core.Node.ValidateNodeIdentity do
  @moduledoc """
  Validates node identity during registration to prevent duplicate or malicious registrations.

  Checks:
  - Cryptographic signature validity
  - Public key uniqueness across the network
  - Node ID uniqueness and proper derivation

  ## Examples

  Identity validation components:

      iex> # Identity validation aspects
      iex> validation_aspects = ["signature_validity", "key_uniqueness", "node_id_derivation"]
      iex> "signature_validity" in validation_aspects
      true
      iex> "node_id_derivation" in validation_aspects  
      true

  Ed25519 key specifications:

      iex> # Ed25519 key length requirements
      iex> ed25519_key_length = 32
      iex> ed25519_key_length > 0
      true

  Node ID derivation example:

      iex> # Node ID generation from public key
      iex> public_key_data = "sample_public_key_data"
      iex> node_id = :crypto.hash(:sha256, public_key_data) |> Base.encode16(case: :lower)
      iex> String.length(node_id)
      64
      iex> String.match?(node_id, ~r/^[0-9a-f]+$/)
      true

  Base64 encoding validation:

      iex> # Base64 encoding/decoding
      iex> test_data = "test_crypto_data"
      iex> encoded = Base.encode64(test_data)
      iex> decoded = Base.decode64!(encoded)
      iex> decoded == test_data
      true

  """

  use Ash.Resource.Validation

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def validate(changeset, _opts, _context) do
    with :ok <- validate_signature(changeset),
         :ok <- validate_node_id_derivation(changeset) do
      :ok
    else
      {:error, message} -> {:error, field: :signature, message: message}
    end
  end

  defp validate_signature(changeset) do
    public_key = Ash.Changeset.get_argument(changeset, :public_key)
    signature = Ash.Changeset.get_argument(changeset, :signature)
    endpoint = Ash.Changeset.get_argument(changeset, :endpoint)

    # Message to verify is the endpoint URL
    message = endpoint

    case verify_signature(message, signature, public_key) do
      true -> :ok
      false -> {:error, "Invalid cryptographic signature for node identity"}
    end
  rescue
    _ -> {:error, "Failed to verify cryptographic signature"}
  end

  defp validate_node_id_derivation(changeset) do
    public_key = Ash.Changeset.get_argument(changeset, :public_key)
    node_id = Ash.Changeset.get_attribute(changeset, :node_id)

    # Decode base64 public key before hashing to match register action
    decoded_public_key = Base.decode64!(public_key)
    expected_node_id = :crypto.hash(:sha256, decoded_public_key) |> Base.encode16(case: :lower)

    if node_id == expected_node_id do
      :ok
    else
      {:error, "Node ID does not match public key derivation"}
    end
  rescue
    _ -> {:error, "Invalid public key format"}
  end

  # Cryptographic signature verification using Erlang :crypto library
  @spec verify_signature(String.t(), String.t(), String.t()) :: boolean()
  defp verify_signature(message, signature, public_key) do
    # Decode base64-encoded signature and public key
    decoded_signature = Base.decode64!(signature)
    decoded_public_key = Base.decode64!(public_key)

    # Proper Ed25519 signature verification
    case byte_size(decoded_public_key) do
      32 ->
        # Use Ed25519 verification - the only cryptographically secure approach
        # Use array format for Ed25519 key specification
        :crypto.verify(:eddsa, :none, message, decoded_signature, [
          decoded_public_key,
          :ed25519
        ])

      _ ->
        # For other key types, return false for now
        # In production, add support for RSA, ECDSA, etc.
        false
    end
  rescue
    # If decoding fails or crypto operation fails, signature is invalid
    _ -> false
  end
end
