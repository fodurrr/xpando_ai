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
    on_exit(fn -> Sandbox.stop_owner(pid) end)
  end

  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
