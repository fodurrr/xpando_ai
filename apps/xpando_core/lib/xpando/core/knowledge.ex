defmodule XPando.Core.Knowledge do
  use Ash.Resource,
    domain: XPando.Core,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table("knowledge")
    repo(XPando.Repo)

    references do
      reference(:contributions, on_delete: :delete, on_update: :update)
    end
  end

  attributes do
    uuid_primary_key(:id)

    # Core Content
    attribute :content, :string do
      description("The actual knowledge content or insight")
      allow_nil?(false)
      constraints(max_length: 10_000, min_length: 10)
    end

    attribute :title, :string do
      description("Brief title or summary of the knowledge")
      allow_nil?(false)
      constraints(max_length: 200)
    end

    attribute :knowledge_type, :atom do
      description("Type of knowledge being stored")
      constraints(one_of: [:insight, :fact, :procedure, :pattern, :hypothesis, :observation])
      default(:insight)
    end

    # Content Integrity
    attribute :content_hash, :string do
      description("SHA-256 hash of the content for integrity verification")
      allow_nil?(false)
      constraints(max_length: 64, min_length: 64)
    end

    attribute :version, :integer do
      description("Version number for content updates")
      default(1)
      constraints(min: 1)
    end

    # Classification and Metadata
    attribute :category, :string do
      description("General category or domain of the knowledge")
      allow_nil?(false)
      constraints(max_length: 100)
    end

    attribute :tags, {:array, :string} do
      description("Searchable tags for knowledge discovery")
      default([])
    end

    attribute :keywords, {:array, :string} do
      description("Important keywords extracted from content")
      default([])
    end

    # Validation and Confidence
    attribute :validation_status, :atom do
      description("Current validation state of the knowledge")
      constraints(one_of: [:pending, :validating, :validated, :disputed, :rejected])
      default(:pending)
    end

    attribute :confidence_score, :decimal do
      description("Consensus confidence score (0.000 to 1.000)")
      constraints(precision: 6, scale: 3, min: 0.0, max: 1.0)
      default(Decimal.new("0.000"))
    end

    attribute :consensus_threshold, :decimal do
      description("Required confidence threshold for validation")
      constraints(precision: 4, scale: 3, min: 0.0, max: 1.0)
      default(Decimal.new("0.750"))
    end

    attribute :validation_count, :integer do
      description("Number of validation attempts received")
      default(0)
      constraints(min: 0)
    end

    attribute :positive_validations, :integer do
      description("Number of positive validation responses")
      default(0)
      constraints(min: 0)
    end

    # Quality and Relevance Metrics
    attribute :relevance_score, :decimal do
      description("Relevance score based on usage and feedback")
      constraints(precision: 4, scale: 3, min: 0.0, max: 1.0)
      default(Decimal.new("0.500"))
    end

    attribute :accuracy_rating, :decimal do
      description("Community-assessed accuracy rating")
      constraints(precision: 4, scale: 3, min: 0.0, max: 1.0)
      default(Decimal.new("0.500"))
    end

    attribute :novelty_score, :decimal do
      description("How novel or unique this knowledge is")
      constraints(precision: 4, scale: 3, min: 0.0, max: 1.0)
      default(Decimal.new("0.500"))
    end

    # Usage and Impact Tracking
    attribute :view_count, :integer do
      description("Number of times this knowledge has been accessed")
      default(0)
      constraints(min: 0)
    end

    attribute :reference_count, :integer do
      description("Number of times this knowledge has been referenced")
      default(0)
      constraints(min: 0)
    end

    attribute :application_count, :integer do
      description("Number of times this knowledge has been applied")
      default(0)
      constraints(min: 0)
    end

    # Temporal and Source Information
    attribute :source_type, :atom do
      description("Origin type of the knowledge")

      constraints(
        one_of: [:human_input, :ai_generated, :collaborative, :experimental, :literature]
      )

      default(:human_input)
    end

    attribute :external_references, {:array, :string} do
      description("Links to external sources or references")
      default([])
    end

    attribute :last_validated_at, :utc_datetime do
      description("Timestamp of most recent validation")
    end

    attribute :expires_at, :utc_datetime do
      description("Optional expiration date for time-sensitive knowledge")
    end

    # Network and Attribution
    attribute :submitter_id, :uuid do
      description("ID of the node that submitted this knowledge")
      allow_nil?(false)
    end

    attribute :validator_nodes, {:array, :uuid} do
      description("List of node IDs that have validated this knowledge")
      default([])
    end

    timestamps()
  end

  actions do
    defaults([:create, :read, :update, :destroy])

    create :submit_for_validation do
      description("Submit new knowledge for network validation")

      argument(:submitter_node_id, :uuid, allow_nil?: false)
      argument(:content, :string, allow_nil?: false)
      argument(:title, :string, allow_nil?: false)
      argument(:category, :string, allow_nil?: false)
      argument(:knowledge_type, :atom, allow_nil?: true)

      change(set_attribute(:submitter_id, arg(:submitter_node_id)))

      change(fn changeset, _context ->
        content = Ash.Changeset.get_argument(changeset, :content)
        hash = :crypto.hash(:sha256, content) |> Base.encode16(case: :lower)
        Ash.Changeset.change_attribute(changeset, :content_hash, hash)
      end)

      change(set_attribute(:validation_status, :pending))

      validate(attribute_does_not_equal(:content, ""))
    end

    update :validate_knowledge do
      description("Add a validation response from a network node")
      require_atomic?(false)

      argument(:validator_node_id, :uuid, allow_nil?: false)
      argument(:is_valid, :boolean, allow_nil?: false)
      argument(:confidence, :decimal, allow_nil?: false)

      change(increment(:validation_count, amount: 1))

      change(fn changeset, _context ->
        is_valid = Ash.Changeset.get_argument(changeset, :is_valid)
        validator_id = Ash.Changeset.get_argument(changeset, :validator_node_id)
        confidence = Ash.Changeset.get_argument(changeset, :confidence)

        changeset =
          if is_valid do
            Ash.Changeset.change_attribute(
              changeset,
              :positive_validations,
              (Ash.Changeset.get_attribute(changeset, :positive_validations) || 0) + 1
            )
          else
            changeset
          end

        # Add validator to the list
        current_validators = Ash.Changeset.get_attribute(changeset, :validator_nodes) || []
        updated_validators = [validator_id | current_validators] |> Enum.uniq()

        changeset
        |> Ash.Changeset.change_attribute(:validator_nodes, updated_validators)
        |> Ash.Changeset.change_attribute(:last_validated_at, DateTime.utc_now())
      end)
    end

    update :finalize_validation do
      description("Complete the validation process and set final status")
      require_atomic?(false)

      change(fn changeset, _context ->
        positive = Ash.Changeset.get_attribute(changeset, :positive_validations) || 0
        total = Ash.Changeset.get_attribute(changeset, :validation_count) || 0

        threshold =
          Ash.Changeset.get_attribute(changeset, :consensus_threshold) || Decimal.new("0.750")

        confidence =
          if total > 0 do
            Decimal.div(Decimal.new(positive), Decimal.new(total))
          else
            Decimal.new("0.000")
          end

        status =
          cond do
            Decimal.gte?(confidence, threshold) -> :validated
            total >= 5 and Decimal.lt?(confidence, Decimal.new("0.250")) -> :rejected
            total >= 10 and Decimal.lt?(confidence, threshold) -> :disputed
            true -> :validating
          end

        changeset
        |> Ash.Changeset.change_attribute(:confidence_score, confidence)
        |> Ash.Changeset.change_attribute(:validation_status, status)
      end)
    end

    update :increment_usage do
      description("Track knowledge usage for metrics")
      require_atomic?(false)

      argument(:usage_type, :atom, allow_nil?: false)

      change(fn changeset, _context ->
        case Ash.Changeset.get_argument(changeset, :usage_type) do
          :view ->
            Ash.Changeset.change_attribute(
              changeset,
              :view_count,
              (Ash.Changeset.get_attribute(changeset, :view_count) || 0) + 1
            )

          :reference ->
            Ash.Changeset.change_attribute(
              changeset,
              :reference_count,
              (Ash.Changeset.get_attribute(changeset, :reference_count) || 0) + 1
            )

          :application ->
            Ash.Changeset.change_attribute(
              changeset,
              :application_count,
              (Ash.Changeset.get_attribute(changeset, :application_count) || 0) + 1
            )

          _ ->
            changeset
        end
      end)
    end

    read :list_validated do
      description("List all validated knowledge items")
      filter(expr(validation_status == :validated))

      prepare(fn query, _context ->
        Ash.Query.sort(query, confidence_score: :desc)
      end)
    end

    read :list_pending_validation do
      description("List knowledge awaiting validation")
      filter(expr(validation_status in [:pending, :validating]))

      prepare(fn query, _context ->
        Ash.Query.sort(query, inserted_at: :asc)
      end)
    end

    read :search_by_category do
      description("Search knowledge by category")

      argument(:category, :string, allow_nil?: false)

      filter(expr(category == ^arg(:category)))
    end

    read :search_by_tags do
      description("Search knowledge by tags")

      argument(:tag, :string, allow_nil?: false)

      filter(expr(^arg(:tag) in tags))
    end

    read :high_confidence do
      description("List high-confidence knowledge items")

      argument(:min_confidence, :decimal, allow_nil?: true)

      prepare(fn query, _context ->
        min_conf = Ash.Query.get_argument(query, :min_confidence) || Decimal.new("0.800")

        query
        |> Ash.Query.filter(expr(confidence_score >= ^min_conf))
        |> Ash.Query.sort(confidence_score: :desc)
      end)
    end

    read :search_content do
      description("Full-text search within knowledge content")

      argument(:search_term, :string, allow_nil?: false)

      prepare(fn query, _context ->
        term = Ash.Query.get_argument(query, :search_term)
        Ash.Query.filter(query, expr(contains(content, ^term) or contains(title, ^term)))
      end)
    end
  end

  relationships do
    belongs_to :submitter, XPando.Core.Node do
      source_attribute(:submitter_id)
      destination_attribute(:id)
    end

    has_many :contributions, XPando.Core.Contribution do
      source_attribute(:id)
      destination_attribute(:knowledge_id)
    end
  end

  calculations do
    calculate :validation_rate,
              :decimal,
              expr(
                if(
                  validation_count > 0,
                  positive_validations / validation_count,
                  decimal("0.0")
                )
              ) do
      description("Calculate percentage of positive validations")
    end

    calculate :total_impact,
              :integer,
              expr(view_count + reference_count * 3 + application_count * 5) do
      description("Weighted impact score based on usage patterns")
    end

    calculate :quality_score,
              :decimal,
              expr(
                confidence_score * decimal("0.4") +
                  accuracy_rating * decimal("0.3") +
                  relevance_score * decimal("0.2") +
                  novelty_score * decimal("0.1")
              ) do
      description("Composite quality score")
    end

    calculate :is_expired, :boolean, expr(not is_nil(expires_at) and expires_at < now()) do
      description("Check if knowledge has expired")
    end
  end

  validations do
    validate(compare(:positive_validations, less_than_or_equal_to: :validation_count),
      message: "Positive validations cannot exceed total validations"
    )

    validate {XPando.Core.Knowledge.ValidateContentHash, []} do
      description("Ensure content hash matches actual content")
    end

    validate(compare(:confidence_score, greater_than_or_equal_to: 0),
      message: "Confidence score must be non-negative"
    )

    validate(compare(:confidence_score, less_than_or_equal_to: 1),
      message: "Confidence score cannot exceed 1.0"
    )
  end

  policies do
    bypass always() do
      authorize_if(actor_attribute_equals(:role, :system))
    end

    policy action(:read) do
      description("Anyone can read validated knowledge")
      authorize_if(expr(validation_status == :validated))
      authorize_if(relates_to_actor_via(:submitter))
    end

    policy action_type(:create) do
      description("Authenticated nodes can submit knowledge")
      authorize_if(actor_attribute_equals(:status, :active))
    end

    policy action_type(:update) do
      description("Only submitter or validators can update knowledge")
      authorize_if(relates_to_actor_via(:submitter))
      authorize_if(actor_attribute_equals(:role, :validator))
    end

    policy action(:destroy) do
      description("Only submitter or administrators can delete knowledge")
      authorize_if(relates_to_actor_via(:submitter))
      authorize_if(actor_attribute_equals(:role, :admin))
    end
  end

  identities do
    identity :unique_content_version, [:content_hash, :version] do
      description("Each content hash + version combination must be unique")
    end
  end
end
