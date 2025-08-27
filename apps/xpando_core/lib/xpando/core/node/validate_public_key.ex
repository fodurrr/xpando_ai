defmodule XPando.Core.Node.ValidatePublicKey do
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
