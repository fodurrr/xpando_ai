defmodule XPandoCore.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      XPando.Repo,
      {AshAuthentication.Supervisor, otp_app: :xpando_core}
    ]

    opts = [strategy: :one_for_one, name: XPandoCore.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
