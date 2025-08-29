defmodule XPando.Core.User do
  @moduledoc """
  User resource for XPando authentication and authorization.

  Manages user accounts with role-based permissions for the distributed AI network.
  Supports node operator authentication and web dashboard access.

  ## Examples

  Check available user roles:

      iex> # Valid user roles in the system
      iex> [:user, :node_operator, :admin]
      [:user, :node_operator, :admin]

  Verify email validation pattern:

      iex> # Test email validation regex
      iex> email_regex = ~r/^[^\s]+@[^\s]+$/
      iex> Regex.match?(email_regex, "valid@example.com")
      true
      iex> Regex.match?(email_regex, "invalid-email")
      false

  Check attribute constraints:

      iex> # Email length constraints
      iex> min_length = 1
      iex> max_length = 160
      iex> test_email = "test@example.com"
      iex> String.length(test_email) >= min_length and String.length(test_email) <= max_length
      true

  """

  use Ash.Resource,
    domain: XPando.Core,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication],
    authorizers: [Ash.Policy.Authorizer]

  attributes do
    uuid_primary_key(:id)

    attribute :email, :ci_string do
      allow_nil?(false)
      public?(true)

      constraints(
        min_length: 1,
        max_length: 160,
        match: ~r/^[^\s]+@[^\s]+$/
      )
    end

    attribute :hashed_password, :string do
      allow_nil?(false)
      sensitive?(true)
    end

    attribute :role, :atom do
      allow_nil?(false)
      default(:user)
      constraints(one_of: [:user, :node_operator, :admin])
    end

    attribute(:confirmed_at, :utc_datetime_usec)

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to :node, XPando.Core.Node do
      allow_nil?(true)
      attribute_writable?(true)
    end
  end

  actions do
    defaults([:read])

    update :update do
      description("Update user attributes")
      accept([:role, :node_id])
      require_atomic?(false)
    end

    read :get_by_subject do
      description("Get a user by the subject claim in a JWT")
      argument(:subject, :string, allow_nil?: false)
      get?(true)
      prepare(AshAuthentication.Preparations.FilterBySubject)
    end

    read :by_email do
      description("Look up a user by email")
      argument(:email, :ci_string, allow_nil?: false)
      get?(true)
      filter(expr(email == ^arg(:email)))
    end
  end

  authentication do
    tokens do
      enabled?(true)
      token_resource(XPando.Core.Token)
      store_all_tokens?(true)
      require_token_presence_for_authentication?(true)

      signing_secret(fn _, _ ->
        Application.fetch_env(:xpando_core, :token_signing_secret)
      end)
    end

    strategies do
      password :password do
        identity_field(:email)
        confirmation_required?(false)
        register_action_accept([:role])
      end
    end

    add_ons do
      log_out_everywhere do
        apply_on_password_change?(true)
      end
    end
  end

  postgres do
    table("users")
    repo(XPando.Repo)
  end

  identities do
    identity(:unique_email, [:email])
  end

  validations do
    validate(match(:email, ~r/^[^\s]+@[^\s]+$/), message: "must be a valid email")
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if(always())
    end

    policy action_type(:read) do
      authorize_if(expr(id == ^actor(:id)))
      authorize_if(actor_attribute_equals(:role, :admin))
    end

    policy action_type(:create) do
      # Allow user registration without actor for password strategy
      authorize_if(action(:register_with_password))
      authorize_if(expr(id == ^actor(:id)))
      authorize_if(actor_attribute_equals(:role, :admin))
    end

    policy action_type([:update, :destroy]) do
      authorize_if(expr(id == ^actor(:id)))
      authorize_if(actor_attribute_equals(:role, :admin))
    end
  end
end
