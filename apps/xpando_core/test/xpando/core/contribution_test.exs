defmodule XPando.Core.ContributionTest do
  use XPando.DataCase

  import XPando.Factory

  alias XPando.Core.Contribution

  describe "create/1" do
    test "creates contribution with valid attributes" do
      node = insert(:node)
      knowledge = insert(:knowledge)

      attrs = %{
        node_id: node.id,
        knowledge_id: knowledge.id,
        contribution_type: :validation,
        quality_score: Decimal.new("8.5"),
        contribution_data: %{validation_method: "peer_review", confidence: 0.85}
      }

      assert {:ok, contribution} =
               Contribution |> Ash.Changeset.for_create(:create, attrs) |> Ash.create()

      assert contribution.node_id == node.id
      assert contribution.knowledge_id == knowledge.id
      assert contribution.contribution_status == :under_review
    end
  end

  describe "record_contribution/1" do
    test "records new contribution with required fields" do
      node = insert(:node)
      knowledge = insert(:knowledge)

      attrs = %{
        node_id: node.id,
        knowledge_id: knowledge.id,
        contribution_type: :enhancement,
        contribution_data: %{enhancement_type: "clarification", description: "Added examples"}
      }

      assert {:ok, contribution} =
               Contribution
               |> Ash.Changeset.for_create(:record_contribution, attrs)
               |> Ash.create()

      assert contribution.contribution_status == :under_review
      assert contribution.contribution_type == :enhancement
    end
  end

  describe "assess_quality/1" do
    test "assesses quality and increments review count" do
      contribution = insert(:contribution, peer_reviews: 2, positive_reviews: 1)
      assessor = insert(:node)

      attrs = %{
        assessor_node_id: assessor.id,
        quality_score: Decimal.new("9.0"),
        accuracy_assessment: Decimal.new("0.900"),
        value_rating: Decimal.new("0.850")
      }

      assert {:ok, updated} =
               contribution |> Ash.Changeset.for_update(:assess_quality, attrs) |> Ash.update()

      assert updated.peer_reviews == 3
      # Should increment for quality >= 7.0
      assert updated.positive_reviews == 2
      assert updated.reviewed_at != nil
      assert updated.quality_score == Decimal.new("9.0")
    end

    test "does not increment positive reviews for low quality" do
      contribution = insert(:contribution, peer_reviews: 2, positive_reviews: 1)
      assessor = insert(:node)

      attrs = %{
        assessor_node_id: assessor.id,
        # Below 7.0 threshold
        quality_score: Decimal.new("5.0"),
        accuracy_assessment: Decimal.new("0.600"),
        value_rating: Decimal.new("0.500")
      }

      assert {:ok, updated} =
               contribution |> Ash.Changeset.for_update(:assess_quality, attrs) |> Ash.update()

      assert updated.peer_reviews == 3
      # Should not increment
      assert updated.positive_reviews == 1
    end
  end

  describe "calculate_rewards/1" do
    test "calculates token rewards based on quality and impact" do
      contribution =
        insert(:contribution,
          quality_score: Decimal.new("8.0"),
          value_rating: Decimal.new("0.750"),
          novelty_factor: Decimal.new("0.600")
        )

      base_rate = Decimal.new("10.0")
      attrs = %{base_rate: base_rate}

      assert {:ok, updated} =
               contribution |> Ash.Changeset.for_update(:calculate_rewards, attrs) |> Ash.update()

      # Base reward = 10.0 * (8.0/10.0) = 8.0
      assert updated.base_reward == Decimal.new("8.0")

      # Quality bonus = 8.0 * (8.0-5.0) * 0.1 = 8.0 * 3.0 * 0.1 = 2.4
      assert updated.quality_bonus == Decimal.new("2.4")

      # Network bonus = 8.0 * (0.750 + 0.600) * 0.25 = 8.0 * 1.35 * 0.25 = 2.7
      assert updated.network_bonus == Decimal.new("2.70")

      # Total = 8.0 + 2.4 + 2.7 = 13.1
      assert updated.total_reward == Decimal.new("13.10")
      assert updated.reward_status == :calculated
    end
  end

  describe "finalize_consensus/1" do
    test "reaches consensus with sufficient positive reviews" do
      contribution = insert(:contribution, peer_reviews: 5, positive_reviews: 4)

      assert {:ok, updated} =
               contribution |> Ash.Changeset.for_update(:finalize_consensus, %{}) |> Ash.update()

      assert updated.consensus_reached == true
      # 4/5
      assert updated.consensus_score == Decimal.new("0.800")
      assert updated.contribution_status == :accepted
      assert updated.accepted_at != nil
    end

    test "rejects contribution with low consensus" do
      contribution = insert(:contribution, peer_reviews: 6, positive_reviews: 2)

      assert {:ok, updated} =
               contribution |> Ash.Changeset.for_update(:finalize_consensus, %{}) |> Ash.update()

      assert updated.consensus_reached == false
      assert updated.consensus_score == Decimal.div(Decimal.new("2"), Decimal.new("6"))
      assert updated.contribution_status == :rejected
    end

    test "keeps under review with insufficient reviews" do
      contribution = insert(:contribution, peer_reviews: 2, positive_reviews: 2)

      assert {:ok, updated} =
               contribution |> Ash.Changeset.for_update(:finalize_consensus, %{}) |> Ash.update()

      assert updated.consensus_reached == false
      assert updated.contribution_status == :under_review
    end
  end

  describe "list_by_node/1" do
    test "returns contributions by specific node" do
      node1 = insert(:node)
      node2 = insert(:node)
      knowledge = insert(:knowledge)

      contribution1 = insert(:contribution, node: node1, knowledge: knowledge)
      _contribution2 = insert(:contribution, node: node2, knowledge: knowledge)

      query = Contribution |> Ash.Query.for_read(:list_by_node, %{node_id: node1.id})
      result = Ash.read!(query)

      assert length(result) == 1
      assert List.first(result).id == contribution1.id
    end
  end

  describe "list_by_knowledge/1" do
    test "returns contributions to specific knowledge" do
      node = insert(:node)
      knowledge1 = insert(:knowledge)
      knowledge2 = insert(:knowledge)

      contribution1 = insert(:contribution, node: node, knowledge: knowledge1)
      _contribution2 = insert(:contribution, node: node, knowledge: knowledge2)

      query =
        Contribution |> Ash.Query.for_read(:list_by_knowledge, %{knowledge_id: knowledge1.id})

      result = Ash.read!(query)

      assert length(result) == 1
      assert List.first(result).id == contribution1.id
    end
  end

  describe "list_high_quality/1" do
    test "returns high quality contributions" do
      high_quality = insert(:contribution, quality_score: Decimal.new("9.0"))
      medium_quality = insert(:contribution, quality_score: Decimal.new("7.0"))
      _low_quality = insert(:contribution, quality_score: Decimal.new("4.0"))

      query =
        Contribution |> Ash.Query.for_read(:list_high_quality, %{min_quality: Decimal.new("8.0")})

      result = Ash.read!(query)

      assert length(result) == 1
      assert List.first(result).id == high_quality.id
    end
  end

  describe "list_by_type/1" do
    test "returns contributions of specific type" do
      validation_contrib = insert(:contribution, contribution_type: :validation)
      _enhancement_contrib = insert(:contribution, contribution_type: :enhancement)

      query = Contribution |> Ash.Query.for_read(:list_by_type, %{contribution_type: :validation})
      result = Ash.read!(query)

      assert length(result) == 1
      assert List.first(result).id == validation_contrib.id
    end
  end

  describe "pending_rewards/0" do
    test "returns contributions with pending rewards" do
      pending = insert(:contribution, reward_status: :pending)
      calculated = insert(:contribution, reward_status: :calculated)
      _distributed = insert(:contribution, reward_status: :distributed)

      result = Contribution |> Ash.Query.for_read(:pending_rewards) |> Ash.read!()

      contribution_ids = Enum.map(result, & &1.id)
      assert pending.id in contribution_ids
      assert calculated.id in contribution_ids
      assert length(result) == 2
    end
  end

  describe "calculations" do
    test "review_rate calculation" do
      contribution = insert(:contribution, peer_reviews: 10, positive_reviews: 7)

      query =
        Contribution |> Ash.Query.load(:review_rate) |> Ash.Query.filter(id: contribution.id)

      [loaded] = Ash.read!(query)

      assert loaded.review_rate == Decimal.new("0.7")
    end

    test "reward_efficiency calculation" do
      contribution =
        insert(:contribution,
          impact_score: Decimal.new("50.0"),
          total_reward: Decimal.new("10.0")
        )

      query =
        Contribution
        |> Ash.Query.load(:reward_efficiency)
        |> Ash.Query.filter(id: contribution.id)

      [loaded] = Ash.read!(query)

      # 50.0 / 10.0
      assert loaded.reward_efficiency == Decimal.new("5.0")
    end

    test "weighted_impact calculation" do
      contribution =
        insert(:contribution,
          impact_score: Decimal.new("10.0"),
          quality_score: Decimal.new("8.0"),
          value_rating: Decimal.new("0.7"),
          novelty_factor: Decimal.new("0.6")
        )

      query =
        Contribution
        |> Ash.Query.load(:weighted_impact)
        |> Ash.Query.filter(id: contribution.id)

      [loaded] = Ash.read!(query)

      # (10.0 * 0.4) + (8.0 * 0.3) + (0.7 * 0.2) + (0.6 * 0.1) = 4.0 + 2.4 + 0.14 + 0.06 = 6.6
      expected = Decimal.new("6.60")
      assert Decimal.eq?(loaded.weighted_impact, expected)
    end
  end

  describe "validations" do
    test "positive reviews cannot exceed total reviews" do
      node = insert(:node)
      knowledge = insert(:knowledge)

      attrs = %{
        node_id: node.id,
        knowledge_id: knowledge.id,
        contribution_type: :validation,
        peer_reviews: 5,
        # Invalid
        positive_reviews: 10
      }

      assert {:error, changeset} =
               Contribution |> Ash.Changeset.for_create(:create, attrs) |> Ash.create()

      assert changeset.errors != []
    end

    test "validates contribution data structure for validation type" do
      node = insert(:node)
      knowledge = insert(:knowledge)

      # Missing required fields for validation type
      attrs = %{
        node_id: node.id,
        knowledge_id: knowledge.id,
        contribution_type: :validation,
        # Missing validation_method and confidence
        contribution_data: %{incomplete: "data"}
      }

      assert {:error, changeset} =
               Contribution |> Ash.Changeset.for_create(:create, attrs) |> Ash.create()

      assert changeset.errors != []
    end
  end

  describe "relationships" do
    test "loads node relationship" do
      node = insert(:node, name: "test-contributor")
      knowledge = insert(:knowledge)
      contribution = insert(:contribution, node: node, knowledge: knowledge)

      query = Contribution |> Ash.Query.load(:node) |> Ash.Query.filter(id: contribution.id)
      [loaded] = Ash.read!(query)

      assert loaded.node.name == "test-contributor"
    end

    test "loads knowledge relationship" do
      node = insert(:node)
      knowledge = insert(:knowledge, title: "Test Knowledge Item")
      contribution = insert(:contribution, node: node, knowledge: knowledge)

      query =
        Contribution |> Ash.Query.load(:knowledge) |> Ash.Query.filter(id: contribution.id)

      [loaded] = Ash.read!(query)

      assert loaded.knowledge.title == "Test Knowledge Item"
    end
  end

  describe "unique constraints" do
    test "prevents duplicate contributions of same type from same node to same knowledge" do
      node = insert(:node)
      knowledge = insert(:knowledge)

      _existing =
        insert(:contribution,
          node: node,
          knowledge: knowledge,
          contribution_type: :validation
        )

      # Try to create another validation contribution from same node to same knowledge
      attrs = %{
        node_id: node.id,
        knowledge_id: knowledge.id,
        contribution_type: :validation,
        contribution_data: %{validation_method: "peer_review", confidence: 0.8}
      }

      assert {:error, changeset} =
               Contribution |> Ash.Changeset.for_create(:create, attrs) |> Ash.create()

      assert changeset.errors != []
    end

    test "allows different contribution types from same node to same knowledge" do
      node = insert(:node)
      knowledge = insert(:knowledge)

      _validation =
        insert(:contribution,
          node: node,
          knowledge: knowledge,
          contribution_type: :validation
        )

      # Different type should be allowed
      attrs = %{
        node_id: node.id,
        knowledge_id: knowledge.id,
        contribution_type: :enhancement,
        contribution_data: %{enhancement_type: "clarification", description: "Added examples"}
      }

      assert {:ok, _contribution} =
               Contribution |> Ash.Changeset.for_create(:create, attrs) |> Ash.create()
    end
  end
end
