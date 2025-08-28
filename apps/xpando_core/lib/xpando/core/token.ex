defmodule XPando.Core.Token do
  @moduledoc """
  Token resource for AshAuthentication.

  This resource stores authentication token metadata and manages token lifecycles
  for secure session management in the xPando distributed AI network.
  """

  use Ash.Resource,
    domain: XPando.Core,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.TokenResource],
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table("tokens")
    repo(XPando.Repo)
  end

  token do
    expunge_interval(24)
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if(always())
    end

    policy always() do
      forbid_if(always())
    end
  end
end
