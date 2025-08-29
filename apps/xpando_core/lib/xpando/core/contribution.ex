defmodule XPando.Core.Contribution do
  @moduledoc """
  Junction resource representing node contributions to knowledge items.

  Tracks quality assessments, token rewards, impact metrics, and consensus
  scoring for contributions made by nodes to the knowledge network.

  ## Examples

  Check valid contribution types:

      iex> # Available contribution type values
      iex> [:submission, :validation, :enhancement, :correction, :verification]
      [:submission, :validation, :enhancement, :correction, :verification]

  Test contribution status workflow:

      iex> # Contribution status progression  
      iex> statuses = [:active, :under_review, :accepted, :rejected, :disputed, :archived]
      iex> :under_review in statuses
      true
      iex> :accepted in statuses
      true

  Calculate review rate example:

      iex> # Review rate calculation
      iex> positive_reviews = 7
      iex> total_reviews = 10
      iex> review_rate = if total_reviews > 0, do: positive_reviews / total_reviews, else: 0.0
      iex> review_rate
      0.7

  Token reward calculation example:

      iex> # Base reward calculation
      iex> base_rate = Decimal.new("100.0")
      iex> quality_score = Decimal.new("8.5")
      iex> base_reward = Decimal.mult(base_rate, Decimal.div(quality_score, Decimal.new("10.0")))
      iex> Decimal.to_float(base_reward)
      85.0

  Weighted impact score:

      iex> # Impact calculation components
      iex> impact = Decimal.new("5.0")
      iex> quality = Decimal.new("8.0")  
      iex> value = Decimal.new("0.7")
      iex> novelty = Decimal.new("0.6")
      iex> weighted = Decimal.mult(impact, Decimal.new("0.4"))
      ...> |> Decimal.add(Decimal.mult(quality, Decimal.new("0.3")))
      ...> |> Decimal.add(Decimal.mult(value, Decimal.new("0.2")))
      ...> |> Decimal.add(Decimal.mult(novelty, Decimal.new("0.1")))
      iex> Decimal.to_float(weighted)
      4.6

  """

  use Ash.Resource,
    domain: XPando.Core,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  require Ash.Query

  postgres do
    table("contributions")
    repo(XPando.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    # Junction Relationships
    attribute :node_id, :uuid do
      description("ID of the contributing node")
      allow_nil?(false)
    end

    attribute :knowledge_id, :uuid do
      description("ID of the knowledge item contributed to")
      allow_nil?(false)
    end

    # Contribution Details
    attribute :contribution_type, :atom do
      description("Type of contribution made")
      constraints(one_of: [:submission, :validation, :enhancement, :correction, :verification])
      allow_nil?(false)
    end

    attribute :contribution_data, :map do
      description("Additional structured data about the contribution")
      default(%{})
    end

    # Quality Assessment
    attribute :quality_score, :decimal do
      description("Assessed quality of this contribution (0.0 to 10.0)")
      constraints(precision: 4, scale: 2, min: 0.0, max: 10.0)
      default(Decimal.new("5.0"))
    end

    attribute :accuracy_assessment, :decimal do
      description("Accuracy assessment by network consensus (0.0 to 1.0)")
      constraints(precision: 4, scale: 3, min: 0.0, max: 1.0)
      default(Decimal.new("0.500"))
    end

    attribute :value_rating, :decimal do
      description("Community value rating for this contribution (0.0 to 1.0)")
      constraints(precision: 4, scale: 3, min: 0.0, max: 1.0)
      default(Decimal.new("0.500"))
    end

    attribute :novelty_factor, :decimal do
      description("How novel or innovative this contribution is")
      constraints(precision: 4, scale: 3, min: 0.0, max: 1.0)
      default(Decimal.new("0.500"))
    end

    # Token Reward System
    attribute :base_reward, :decimal do
      description("Base token reward for this contribution")
      constraints(precision: 10, scale: 4, min: 0.0)
      default(Decimal.new("0.0000"))
    end

    attribute :quality_bonus, :decimal do
      description("Additional reward based on quality assessment")
      constraints(precision: 10, scale: 4, min: 0.0)
      default(Decimal.new("0.0000"))
    end

    attribute :network_bonus, :decimal do
      description("Bonus based on network participation and reputation")
      constraints(precision: 10, scale: 4, min: 0.0)
      default(Decimal.new("0.0000"))
    end

    attribute :total_reward, :decimal do
      description("Total token reward (base + bonuses)")
      constraints(precision: 10, scale: 4, min: 0.0)
      default(Decimal.new("0.0000"))
    end

    attribute :reward_status, :atom do
      description("Status of reward payment")
      constraints(one_of: [:pending, :calculated, :distributed, :disputed, :revoked])
      default(:pending)
    end

    # Impact and Influence Metrics
    attribute :impact_score, :decimal do
      description("Measured impact of this contribution on the network")
      constraints(precision: 6, scale: 3, min: 0.0)
      default(Decimal.new("0.000"))
    end

    attribute :influence_factor, :decimal do
      description("How much this contribution influences other work")
      constraints(precision: 4, scale: 3, min: 0.0, max: 1.0)
      default(Decimal.new("0.000"))
    end

    attribute :citation_count, :integer do
      description("Number of times this contribution has been cited")
      default(0)
      constraints(min: 0)
    end

    # Validation and Consensus
    attribute :peer_reviews, :integer do
      description("Number of peer reviews received")
      default(0)
      constraints(min: 0)
    end

    attribute :positive_reviews, :integer do
      description("Number of positive peer reviews")
      default(0)
      constraints(min: 0)
    end

    attribute :consensus_reached, :boolean do
      description("Whether network consensus has been reached on this contribution")
      default(false)
    end

    attribute :consensus_score, :decimal do
      description("Final consensus score from network evaluation")
      constraints(precision: 4, scale: 3, min: 0.0, max: 1.0)
      default(Decimal.new("0.000"))
    end

    # Temporal and Status Information
    attribute :contribution_status, :atom do
      description("Current status of the contribution")
      constraints(one_of: [:active, :under_review, :accepted, :rejected, :disputed, :archived])
      default(:under_review)
    end

    attribute :reviewed_at, :utc_datetime do
      description("Timestamp when contribution was last reviewed")
    end

    attribute :accepted_at, :utc_datetime do
      description("Timestamp when contribution was accepted")
    end

    attribute :expires_at, :utc_datetime do
      description("Optional expiration date for time-sensitive contributions")
    end

    # Feedback and Learning
    attribute :feedback_score, :decimal do
      description("Aggregated feedback score from community")
      constraints(precision: 4, scale: 2, min: 0.0, max: 10.0)
      default(Decimal.new("5.0"))
    end

    attribute :learning_value, :decimal do
      description("Educational value of this contribution")
      constraints(precision: 4, scale: 3, min: 0.0, max: 1.0)
      default(Decimal.new("0.500"))
    end

    timestamps()
  end

  actions do
    defaults([:create, :read, :update, :destroy])

    create :record_contribution do
      description("Record a new contribution from a node")

      argument(:node_id, :uuid, allow_nil?: false)
      argument(:knowledge_id, :uuid, allow_nil?: false)
      argument(:contribution_type, :atom, allow_nil?: false)
      argument(:contribution_data, :map, allow_nil?: true)

      change(set_attribute(:contribution_status, :under_review))

      validate(present([:node_id, :knowledge_id, :contribution_type]))
    end

    update :assess_quality do
      description("Assess the quality of a contribution")
      require_atomic?(false)

      argument(:assessor_node_id, :uuid, allow_nil?: false)
      argument(:quality_score, :decimal, allow_nil?: false)
      argument(:accuracy_assessment, :decimal, allow_nil?: false)
      argument(:value_rating, :decimal, allow_nil?: false)

      change(increment(:peer_reviews, amount: 1))
      change(set_attribute(:reviewed_at, &DateTime.utc_now/0))

      change(fn changeset, _context ->
        quality = Ash.Changeset.get_argument(changeset, :quality_score)

        if Decimal.gte?(quality, Decimal.new("7.0")) do
          Ash.Changeset.change_attribute(
            changeset,
            :positive_reviews,
            (Ash.Changeset.get_attribute(changeset, :positive_reviews) || 0) + 1
          )
        else
          changeset
        end
      end)
    end

    update :calculate_rewards do
      description("Calculate token rewards based on contribution quality and impact")
      require_atomic?(false)

      argument(:base_rate, :decimal, allow_nil?: false)

      change(fn changeset, _context ->
        base_rate = Ash.Changeset.get_argument(changeset, :base_rate)
        quality = Ash.Changeset.get_attribute(changeset, :quality_score) || Decimal.new("5.0")
        value_rating = Ash.Changeset.get_attribute(changeset, :value_rating) || Decimal.new("0.5")
        novelty = Ash.Changeset.get_attribute(changeset, :novelty_factor) || Decimal.new("0.5")

        # Calculate base reward
        base_reward = Decimal.mult(base_rate, Decimal.div(quality, Decimal.new("10.0")))

        # Calculate quality bonus (up to 50% additional)
        quality_bonus =
          Decimal.mult(
            base_reward,
            Decimal.mult(Decimal.sub(quality, Decimal.new("5.0")), Decimal.new("0.1"))
          )

        # Calculate network bonus based on value and novelty
        network_multiplier = Decimal.mult(Decimal.add(value_rating, novelty), Decimal.new("0.25"))
        network_bonus = Decimal.mult(base_reward, network_multiplier)

        total_reward = Decimal.add(Decimal.add(base_reward, quality_bonus), network_bonus)

        changeset
        |> Ash.Changeset.change_attribute(:base_reward, base_reward)
        |> Ash.Changeset.change_attribute(:quality_bonus, quality_bonus)
        |> Ash.Changeset.change_attribute(:network_bonus, network_bonus)
        |> Ash.Changeset.change_attribute(:total_reward, total_reward)
        |> Ash.Changeset.change_attribute(:reward_status, :calculated)
      end)
    end

    update :finalize_consensus do
      description("Finalize network consensus on the contribution")
      require_atomic?(false)

      change(fn changeset, _context ->
        positive = Ash.Changeset.get_attribute(changeset, :positive_reviews) || 0
        total = Ash.Changeset.get_attribute(changeset, :peer_reviews) || 0

        consensus_score =
          if total > 0 do
            Decimal.div(Decimal.new(positive), Decimal.new(total))
          else
            Decimal.new("0.000")
          end

        consensus_reached = total >= 3 and Decimal.gte?(consensus_score, Decimal.new("0.667"))

        status =
          cond do
            consensus_reached and Decimal.gte?(consensus_score, Decimal.new("0.8")) -> :accepted
            consensus_reached and Decimal.gte?(consensus_score, Decimal.new("0.6")) -> :active
            total >= 5 and Decimal.lt?(consensus_score, Decimal.new("0.4")) -> :rejected
            true -> :under_review
          end

        changeset
        |> Ash.Changeset.change_attribute(:consensus_score, consensus_score)
        |> Ash.Changeset.change_attribute(:consensus_reached, consensus_reached)
        |> Ash.Changeset.change_attribute(:contribution_status, status)
        |> then(fn ch ->
          if status == :accepted do
            Ash.Changeset.change_attribute(ch, :accepted_at, DateTime.utc_now())
          else
            ch
          end
        end)
      end)
    end

    read :list_by_node do
      description("List all contributions by a specific node")

      argument(:node_id, :uuid, allow_nil?: false)

      filter(expr(node_id == ^arg(:node_id)))

      prepare(fn query, _context ->
        Ash.Query.sort(query, inserted_at: :desc)
      end)
    end

    read :list_by_knowledge do
      description("List all contributions to a specific knowledge item")

      argument(:knowledge_id, :uuid, allow_nil?: false)

      filter(expr(knowledge_id == ^arg(:knowledge_id)))

      prepare(fn query, _context ->
        Ash.Query.sort(query, inserted_at: :desc)
      end)
    end

    read :list_high_quality do
      description("List high-quality contributions")

      argument(:min_quality, :decimal, allow_nil?: true)

      prepare(fn query, _context ->
        min_qual = Ash.Query.get_argument(query, :min_quality) || Decimal.new("8.0")

        query
        |> Ash.Query.filter(expr(quality_score >= ^min_qual))
        |> Ash.Query.sort(quality_score: :desc)
      end)
    end

    read :list_by_type do
      description("List contributions by type")

      argument(:contribution_type, :atom, allow_nil?: false)

      filter(expr(contribution_type == ^arg(:contribution_type)))
    end

    read :pending_rewards do
      description("List contributions with pending reward calculations")

      filter(expr(reward_status in [:pending, :calculated]))

      prepare(fn query, _context ->
        Ash.Query.sort(query, inserted_at: :asc)
      end)
    end
  end

  relationships do
    belongs_to :node, XPando.Core.Node do
      source_attribute(:node_id)
      destination_attribute(:id)
    end

    belongs_to :knowledge, XPando.Core.Knowledge do
      source_attribute(:knowledge_id)
      destination_attribute(:id)
    end
  end

  calculations do
    calculate :review_rate,
              :decimal,
              expr(
                if peer_reviews > 0 do
                  positive_reviews / peer_reviews
                else
                  decimal("0.0")
                end
              ) do
      description("Calculate percentage of positive reviews")
    end

    calculate :reward_efficiency,
              :decimal,
              expr(
                if total_reward > 0 do
                  impact_score / total_reward
                else
                  decimal("0.0")
                end
              ) do
      description("Calculate impact per token rewarded")
    end

    calculate :weighted_impact,
              :decimal,
              expr(
                impact_score * decimal("0.4") +
                  quality_score * decimal("0.3") +
                  value_rating * decimal("0.2") +
                  novelty_factor * decimal("0.1")
              ) do
      description("Composite weighted impact score")
    end

    calculate :is_expired, :boolean, expr(not is_nil(expires_at) and expires_at < now()) do
      description("Check if contribution has expired")
    end
  end

  validations do
    validate(compare(:positive_reviews, less_than_or_equal_to: :peer_reviews),
      message: "Positive reviews cannot exceed total reviews"
    )

    validate(compare(:total_reward, greater_than_or_equal_to: 0),
      message: "Total reward must be non-negative"
    )

    validate {XPando.Core.Contribution.ValidateContributionData, []} do
      description("Validate contribution data structure")
    end
  end

  policies do
    bypass always() do
      authorize_if(actor_attribute_equals(:role, :system))
    end

    policy action(:read) do
      description("Anyone can read active contributions")
      authorize_if(expr(contribution_status in [:active, :accepted]))
      authorize_if(relates_to_actor_via(:node))
    end

    policy action_type(:create) do
      description("Active nodes can create contributions")
      authorize_if(actor_attribute_equals(:status, :active))
    end

    policy action_type(:update) do
      description("Contributors and reviewers can update contributions")
      authorize_if(relates_to_actor_via(:node))
      authorize_if(actor_attribute_equals(:role, :reviewer))
      authorize_if(actor_attribute_equals(:role, :admin))
    end

    policy action(:destroy) do
      description("Only contributors or administrators can delete contributions")
      authorize_if(relates_to_actor_via(:node))
      authorize_if(actor_attribute_equals(:role, :admin))
    end
  end

  identities do
    identity :unique_node_knowledge_type, [:node_id, :knowledge_id, :contribution_type] do
      description("Each node can only have one contribution of each type per knowledge item")
    end
  end
end
