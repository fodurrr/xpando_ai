defmodule XPando.Core.Node do
  @moduledoc """
  Core domain resource representing network nodes in the xPando P2P network.

  Nodes are AI participants with cryptographic identities, reputation scores,
  and network connection capabilities for distributed knowledge sharing.
  """

  use Ash.Resource,
    domain: XPando.Core,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication],
    authorizers: [Ash.Policy.Authorizer]

  require Ash.Query

  postgres do
    table("nodes")
    repo(XPando.Repo)

    references do
      reference(:contributions, on_delete: :delete, on_update: :update)
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :name, :string do
      description("Human-readable node identifier")
      allow_nil?(false)
      constraints(max_length: 255)
    end

    # Cryptographic Identity
    attribute :public_key, :string do
      description("Node's cryptographic public key for identity verification")
      allow_nil?(false)
      constraints(max_length: 1024)
    end

    attribute :private_key_hash, :string do
      description("Hash of the private key for verification without exposing the key")
      allow_nil?(false)
      constraints(max_length: 128)
    end

    attribute :node_signature, :string do
      description("Cryptographic signature proving node ownership")
      allow_nil?(false)
      constraints(max_length: 512)
    end

    # Network Information
    attribute :endpoint, :string do
      description("Network endpoint URL for P2P communication")
      allow_nil?(false)
      constraints(max_length: 512)
    end

    attribute :port, :integer do
      description("Network port for P2P communication")
      default(8080)
      constraints(min: 1, max: 65_535)
    end

    # Connection State
    attribute :status, :atom do
      description("Current operational status of the node")
      constraints(one_of: [:active, :inactive, :maintenance, :suspended])
      default(:inactive)
    end

    attribute :last_seen_at, :utc_datetime do
      description("Timestamp of last network activity")
    end

    attribute :connection_count, :integer do
      description("Number of active connections to other nodes")
      default(0)
      constraints(min: 0)
    end

    # Specialization and Expertise
    attribute :specializations, {:array, :string} do
      description("List of specialized domains or capabilities")
      default([])
    end

    attribute :expertise_level, :decimal do
      description("Overall expertise rating (0.0 to 10.0)")
      constraints(precision: 3, scale: 1, min: 0.0, max: 10.0)
      default(Decimal.new("5.0"))
    end

    # Reputation System
    attribute :reputation_score, :decimal do
      description("Consensus-based reputation score (0.0 to 100.0)")
      constraints(precision: 5, scale: 2, min: 0.0, max: 100.0)
      default(Decimal.new("50.0"))
    end

    attribute :trust_rating, :decimal do
      description("Network trust rating based on validation accuracy")
      constraints(precision: 4, scale: 3, min: 0.0, max: 1.0)
      default(Decimal.new("0.500"))
    end

    attribute :validation_accuracy, :decimal do
      description("Historical accuracy of knowledge validations")
      constraints(precision: 4, scale: 3, min: 0.0, max: 1.0)
      default(Decimal.new("0.500"))
    end

    # Operational Metrics
    attribute :total_validations, :integer do
      description("Total number of validations performed by this node")
      default(0)
      constraints(min: 0)
    end

    attribute :successful_validations, :integer do
      description("Number of successful validations")
      default(0)
      constraints(min: 0)
    end

    attribute :knowledge_contributions, :integer do
      description("Total knowledge items contributed")
      default(0)
      constraints(min: 0)
    end

    # Regional and Performance Data
    attribute :region, :string do
      description("Geographic or network region identifier")
      constraints(max_length: 100)
    end

    attribute :response_time_avg, :integer do
      description("Average response time in milliseconds")
      constraints(min: 0)
    end

    attribute :uptime_percentage, :decimal do
      description("Node uptime as percentage")
      constraints(precision: 5, scale: 2, min: 0.0, max: 100.0)
      default(Decimal.new("0.0"))
    end

    timestamps()
  end

  actions do
    defaults([:create, :read, :update, :destroy])

    create :register do
      description("Register a new node in the network")

      argument(:endpoint, :string, allow_nil?: false)
      argument(:public_key, :string, allow_nil?: false)
      argument(:signature, :string, allow_nil?: false)

      change(set_attribute(:status, :active))
      change(set_attribute(:last_seen_at, &DateTime.utc_now/0))

      validate(attribute_equals(:status, :active))
    end

    update :update_reputation do
      description("Update node reputation based on validation performance")
      require_atomic?(false)

      argument(:new_reputation, :decimal, allow_nil?: false)
      argument(:validation_result, :boolean, allow_nil?: false)

      change(set_attribute(:reputation_score, arg(:new_reputation)))
      change(increment(:total_validations, amount: 1))

      change(fn changeset, _context ->
        if Ash.Changeset.get_argument(changeset, :validation_result) do
          Ash.Changeset.change_attribute(
            changeset,
            :successful_validations,
            (Ash.Changeset.get_attribute(changeset, :successful_validations) || 0) + 1
          )
        else
          changeset
        end
      end)
    end

    update :update_activity do
      description("Update node activity status and metrics")
      require_atomic?(false)

      argument(:connections, :integer, allow_nil?: true)

      change(set_attribute(:last_seen_at, &DateTime.utc_now/0))
      change(set_attribute(:status, :active))

      change(fn changeset, _context ->
        if connection_count = Ash.Changeset.get_argument(changeset, :connections) do
          Ash.Changeset.change_attribute(changeset, :connection_count, connection_count)
        else
          changeset
        end
      end)
    end

    read :list_active do
      description("List all active nodes in the network")
      filter(expr(status == :active))
    end

    read :list_by_specialization do
      description("Find nodes by specialization")

      argument(:specialization, :string, allow_nil?: false)

      filter(expr(^arg(:specialization) in specializations))
    end

    read :list_high_reputation do
      description("List nodes with high reputation scores")

      argument(:min_reputation, :decimal, allow_nil?: true)

      prepare(fn query, _context ->
        min_rep = Ash.Query.get_argument(query, :min_reputation) || Decimal.new("75.0")

        query
        |> Ash.Query.filter(expr(reputation_score >= ^min_rep))
        |> Ash.Query.sort(reputation_score: :desc)
      end)
    end
  end

  relationships do
    has_many :contributed_knowledge, XPando.Core.Knowledge do
      source_attribute(:id)
      destination_attribute(:submitter_id)
    end

    has_many :contributions, XPando.Core.Contribution do
      source_attribute(:id)
      destination_attribute(:node_id)
    end
  end

  preparations do
    prepare(build(load: [:contributed_knowledge, :contributions]))
  end

  calculations do
    calculate :success_rate,
              :decimal,
              expr(
                if total_validations > 0 do
                  successful_validations / total_validations
                else
                  decimal("0.0")
                end
              ) do
      description("Calculate validation success rate")
    end

    calculate :contribution_score,
              :decimal,
              expr(
                knowledge_contributions * decimal("10.0") +
                  successful_validations * decimal("5.0")
              ) do
      description("Overall contribution score based on knowledge and validations")
    end
  end

  validations do
    validate(compare(:successful_validations, less_than_or_equal_to: :total_validations),
      message: "Successful validations cannot exceed total validations"
    )

    validate {XPando.Core.Node.ValidatePublicKey, []} do
      description("Validate cryptographic public key format")
    end

    validate(compare(:reputation_score, greater_than_or_equal_to: 0),
      message: "Reputation score must be non-negative"
    )
  end

  policies do
    bypass always() do
      authorize_if(actor_attribute_equals(:role, :system))
    end

    policy action(:read) do
      description("Anyone can read public node information")
      authorize_if(always())
    end

    policy action_type(:create) do
      description("New nodes can self-register with valid cryptographic proof")
      authorize_if(always())
    end

    policy action_type(:update) do
      description("Only the node itself or system can update node data")
      authorize_if(relates_to_actor_via(:id))
      authorize_if(actor_attribute_equals(:role, :system))
    end

    policy action(:destroy) do
      description("Only system administrators can remove nodes")
      authorize_if(actor_attribute_equals(:role, :admin))
    end
  end

  identities do
    identity :unique_public_key, [:public_key] do
      description("Each node must have a unique public key")
    end

    identity :unique_endpoint, [:endpoint, :port] do
      description("Each endpoint:port combination must be unique")
    end
  end
end
