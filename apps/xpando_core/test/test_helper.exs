ExUnit.start()

# Setup Ecto sandbox
Ecto.Adapters.SQL.Sandbox.mode(XPando.Repo, :manual)

# Setup ExMachina
{:ok, _} = Application.ensure_all_started(:ex_machina)
