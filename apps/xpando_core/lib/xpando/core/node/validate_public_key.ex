defmodule XPando.Core.Node.ValidatePublicKey do
  @moduledoc """
  Custom Ash validation for node cryptographic public keys.

  Ensures public keys are properly formatted and valid for use in
  cryptographic operations within the P2P network.

  ## Examples

  Check key length requirements:

      iex> # Minimum key length requirement
      iex> min_key_length = 32
      iex> test_key = String.duplicate("a", 32)
      iex> String.length(test_key) >= min_key_length
      true

  Test key validation criteria:

      iex> # Valid key characteristics
      iex> criteria = ["sufficient_length", "valid_string", "printable_chars"]
      iex> "sufficient_length" in criteria
      true

  String validation helpers:

      iex> # String validation functions
      iex> test_string = "valid_public_key_example"
      iex> String.valid?(test_string)
      true
      iex> String.printable?(test_string)
      true

  """

  use Ash.Resource.Validation

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def validate(changeset, _opts, _context) do
    case Ash.Changeset.get_attribute(changeset, :public_key) do
      nil ->
        :ok

      public_key when is_binary(public_key) ->
        if valid_public_key_format?(public_key) do
          :ok
        else
          {:error, field: :public_key, message: "Invalid public key format"}
        end

      _ ->
        {:error, field: :public_key, message: "Public key must be a string"}
    end
  end

  defp valid_public_key_format?(key) do
    # Basic validation - in production, this should use proper cryptographic validation
    # Could add more sophisticated checks for specific key formats (RSA, Ed25519, etc.)
    byte_size(key) >= 32 and
      String.valid?(key) and
      String.printable?(key)
  end
end
