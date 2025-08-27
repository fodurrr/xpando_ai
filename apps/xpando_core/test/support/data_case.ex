defmodule XPando.DataCase do
  @moduledoc """
  Test case template for xPando database-related tests.

  Provides database transaction handling, Ecto imports, and factory
  setup for tests that interact with the PostgreSQL database.
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
      import XPando.Factory
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
