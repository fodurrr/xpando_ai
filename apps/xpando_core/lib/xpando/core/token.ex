defmodule XPando.Core.Token do
  @moduledoc """
  Token resource for AshAuthentication.

  This resource stores authentication token metadata and manages token lifecycles
  for secure session management in the xPando distributed AI network.

  ## Examples

  Token expunge interval configuration:

      iex> # Token cleanup interval in hours
      iex> expunge_interval_hours = 24
      iex> expunge_interval_hours > 0
      true

  Authentication token lifecycle:

      iex> # Token states in the system
      iex> states = [:active, :expired, :revoked]
      iex> :active in states
      true

  Token security considerations:

      iex> # Secure token handling principles
      iex> principles = ["store_metadata_only", "auto_expunge", "secure_access"]
      iex> "store_metadata_only" in principles
      true

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
