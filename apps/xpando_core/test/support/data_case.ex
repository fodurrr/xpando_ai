defmodule XPando.DataCase do
  @moduledoc """
  Test case template for xPando database-related tests.

  Provides database transaction handling, Ash imports, and generator
  setup for tests that interact with Ash resources and PostgreSQL database.
  """

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      alias XPando.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import XPando.DataCase
      import XPando.TestGenerators

      # Ash testing imports
      import Ash.Test
      import Ash.Generator, only: [generate: 1, generate_many: 2]
      import Ash.Seed, only: [seed!: 2]

      # Required for Ash.Query.filter usage
      require Ash.Query
    end
  end

  setup tags do
    XPando.DataCase.setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    pid = Sandbox.start_owner!(XPando.Repo, shared: not tags[:async])
    ExUnit.Callbacks.on_exit(fn -> Sandbox.stop_owner(pid) end)
  end

  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  # Helper to generate valid Ed25519 key-signature pairs for proper registration tests
  def generate_valid_node_identity(endpoint) do
    # Generate real Ed25519 key pair for proper cryptographic testing
    {public_key, private_key} = :crypto.generate_key(:eddsa, :ed25519)

    # Create proper Ed25519 signature for the endpoint message
    message_to_sign = endpoint
    signature = :crypto.sign(:eddsa, :none, message_to_sign, [private_key, :ed25519])

    %{
      public_key: Base.encode64(public_key),
      signature: Base.encode64(signature)
    }
  end
end
