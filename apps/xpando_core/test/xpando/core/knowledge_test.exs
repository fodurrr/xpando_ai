defmodule XPando.Core.KnowledgeTest do
  use XPando.DataCase

  import XPando.Factory

  alias XPando.Core.Knowledge

  describe "create/1" do
    test "creates knowledge with valid attributes" do
      node = insert(:node)
      content = "Test knowledge content for distributed systems"

      attrs = %{
        title: "Test Knowledge",
        content: content,
        content_hash: :crypto.hash(:sha256, content) |> Base.encode16(case: :lower),
        category: "technology",
        submitter_id: node.id
      }

      assert {:ok, knowledge} =
               Knowledge |> Ash.Changeset.for_create(:create, attrs) |> Ash.create()

      assert knowledge.title == attrs.title
      assert knowledge.validation_status == :pending
      assert knowledge.confidence_score == Decimal.new("0.000")
    end

    test "fails with invalid content hash" do
      node = insert(:node)

      attrs = %{
        title: "Test Knowledge",
        content: "Some content",
        # Doesn't match content
        content_hash: "invalid_hash",
        category: "technology",
        submitter_id: node.id
      }

      assert {:error, changeset} =
               Knowledge |> Ash.Changeset.for_create(:create, attrs) |> Ash.create()

      assert changeset.errors != []
    end
  end

  describe "submit_for_validation/1" do
    test "submits knowledge with auto-generated hash" do
      node = insert(:node)
      content = "Knowledge content to be validated"

      attrs = %{
        submitter_node_id: node.id,
        content: content,
        title: "New Knowledge",
        category: "science"
      }

      assert {:ok, knowledge} =
               Knowledge
               |> Ash.Changeset.for_create(:submit_for_validation, attrs)
               |> Ash.create()

      assert knowledge.submitter_id == node.id
      assert knowledge.validation_status == :pending

      expected_hash = :crypto.hash(:sha256, content) |> Base.encode16(case: :lower)
      assert knowledge.content_hash == expected_hash
    end
  end

  describe "validate_knowledge/1" do
    test "adds validation from network node" do
      node = insert(:node)
      knowledge = insert(:knowledge, validation_count: 2, positive_validations: 1)
      validator = insert(:node)

      attrs = %{
        validator_node_id: validator.id,
        is_valid: true,
        confidence: Decimal.new("0.85")
      }

      assert {:ok, updated} =
               knowledge |> Ash.Changeset.for_update(:validate_knowledge, attrs) |> Ash.update()

      assert updated.validation_count == 3
      assert updated.positive_validations == 2
      assert validator.id in updated.validator_nodes
      assert updated.last_validated_at != nil
    end

    test "handles negative validation" do
      knowledge = insert(:knowledge, validation_count: 2, positive_validations: 2)
      validator = insert(:node)

      attrs = %{
        validator_node_id: validator.id,
        is_valid: false,
        confidence: Decimal.new("0.30")
      }

      assert {:ok, updated} =
               knowledge |> Ash.Changeset.for_update(:validate_knowledge, attrs) |> Ash.update()

      assert updated.validation_count == 3
      # Should not increment
      assert updated.positive_validations == 2
      assert validator.id in updated.validator_nodes
    end
  end

  describe "finalize_validation/1" do
    test "validates knowledge when threshold is met" do
      knowledge =
        insert(:knowledge,
          validation_count: 5,
          positive_validations: 4,
          consensus_threshold: Decimal.new("0.750")
        )

      assert {:ok, updated} =
               knowledge |> Ash.Changeset.for_update(:finalize_validation, %{}) |> Ash.update()

      assert updated.validation_status == :validated
      # 4/5
      assert updated.confidence_score == Decimal.new("0.800")
    end

    test "rejects knowledge with low confidence" do
      knowledge =
        insert(:knowledge,
          validation_count: 6,
          positive_validations: 1,
          consensus_threshold: Decimal.new("0.750")
        )

      assert {:ok, updated} =
               knowledge |> Ash.Changeset.for_update(:finalize_validation, %{}) |> Ash.update()

      assert updated.validation_status == :rejected
      assert updated.confidence_score == Decimal.div(Decimal.new("1"), Decimal.new("6"))
    end

    test "sets disputed status for moderate disagreement" do
      knowledge =
        insert(:knowledge,
          validation_count: 12,
          # 50% - below threshold but not rejected
          positive_validations: 6,
          consensus_threshold: Decimal.new("0.750")
        )

      assert {:ok, updated} =
               knowledge |> Ash.Changeset.for_update(:finalize_validation, %{}) |> Ash.update()

      assert updated.validation_status == :disputed
      assert updated.confidence_score == Decimal.new("0.500")
    end
  end

  describe "increment_usage/1" do
    test "increments view count" do
      knowledge = insert(:knowledge, view_count: 5)

      attrs = %{usage_type: :view}

      assert {:ok, updated} =
               knowledge |> Ash.Changeset.for_update(:increment_usage, attrs) |> Ash.update()

      assert updated.view_count == 6
    end

    test "increments reference count" do
      knowledge = insert(:knowledge, reference_count: 3)

      attrs = %{usage_type: :reference}

      assert {:ok, updated} =
               knowledge |> Ash.Changeset.for_update(:increment_usage, attrs) |> Ash.update()

      assert updated.reference_count == 4
    end

    test "increments application count" do
      knowledge = insert(:knowledge, application_count: 2)

      attrs = %{usage_type: :application}

      assert {:ok, updated} =
               knowledge |> Ash.Changeset.for_update(:increment_usage, attrs) |> Ash.update()

      assert updated.application_count == 3
    end
  end

  describe "list_validated/0" do
    test "returns only validated knowledge" do
      validated = insert(:knowledge, validation_status: :validated)
      _pending = insert(:knowledge, validation_status: :pending)
      _rejected = insert(:knowledge, validation_status: :rejected)

      result = Knowledge |> Ash.Query.for_read(:list_validated) |> Ash.read!()

      assert length(result) == 1
      assert List.first(result).id == validated.id
    end
  end

  describe "search_by_category/1" do
    test "finds knowledge by category" do
      tech_knowledge = insert(:knowledge, category: "technology")
      _science_knowledge = insert(:knowledge, category: "science")

      query = Knowledge |> Ash.Query.for_read(:search_by_category, %{category: "technology"})
      result = Ash.read!(query)

      assert length(result) == 1
      assert List.first(result).id == tech_knowledge.id
    end
  end

  describe "search_by_tags/1" do
    test "finds knowledge by tag" do
      ai_knowledge = insert(:knowledge, tags: ["ai", "machine_learning"])
      _blockchain_knowledge = insert(:knowledge, tags: ["blockchain", "crypto"])

      query = Knowledge |> Ash.Query.for_read(:search_by_tags, %{tag: "ai"})
      result = Ash.read!(query)

      assert length(result) == 1
      assert List.first(result).id == ai_knowledge.id
    end
  end

  describe "high_confidence/1" do
    test "returns high confidence knowledge" do
      high_conf = insert(:knowledge, confidence_score: Decimal.new("0.900"))
      medium_conf = insert(:knowledge, confidence_score: Decimal.new("0.700"))
      _low_conf = insert(:knowledge, confidence_score: Decimal.new("0.300"))

      query =
        Knowledge |> Ash.Query.for_read(:high_confidence, %{min_confidence: Decimal.new("0.800")})

      result = Ash.read!(query)

      assert length(result) == 1
      assert List.first(result).id == high_conf.id
    end
  end

  describe "calculations" do
    test "validation_rate calculation" do
      knowledge = insert(:knowledge, validation_count: 10, positive_validations: 7)

      query =
        Knowledge |> Ash.Query.load(:validation_rate) |> Ash.Query.filter(id: knowledge.id)

      [loaded] = Ash.read!(query)

      assert loaded.validation_rate == Decimal.new("0.7")
    end

    test "total_impact calculation" do
      knowledge =
        insert(:knowledge,
          view_count: 10,
          reference_count: 3,
          application_count: 2
        )

      query = Knowledge |> Ash.Query.load(:total_impact) |> Ash.Query.filter(id: knowledge.id)
      [loaded] = Ash.read!(query)

      # 10 + (3*3) + (2*5) = 10 + 9 + 10 = 29
      assert loaded.total_impact == 29
    end

    test "quality_score calculation" do
      knowledge =
        insert(:knowledge,
          confidence_score: Decimal.new("0.8"),
          accuracy_rating: Decimal.new("0.9"),
          relevance_score: Decimal.new("0.7"),
          novelty_score: Decimal.new("0.6")
        )

      query = Knowledge |> Ash.Query.load(:quality_score) |> Ash.Query.filter(id: knowledge.id)
      [loaded] = Ash.read!(query)

      # (0.8 * 0.4) + (0.9 * 0.3) + (0.7 * 0.2) + (0.6 * 0.1) = 0.32 + 0.27 + 0.14 + 0.06 = 0.79
      expected = Decimal.new("0.79")
      assert Decimal.eq?(loaded.quality_score, expected)
    end
  end

  describe "validations" do
    test "positive validations cannot exceed total validations" do
      node = insert(:node)

      attrs = %{
        title: "Test Knowledge",
        content: "Some content",
        content_hash: :crypto.hash(:sha256, "Some content") |> Base.encode16(case: :lower),
        category: "test",
        submitter_id: node.id,
        validation_count: 5,
        # Invalid
        positive_validations: 10
      }

      assert {:error, changeset} =
               Knowledge |> Ash.Changeset.for_create(:create, attrs) |> Ash.create()

      assert changeset.errors != []
    end
  end

  describe "relationships" do
    test "loads submitter node" do
      node = insert(:node, name: "test-submitter")
      knowledge = insert(:knowledge, submitter: node)

      query = Knowledge |> Ash.Query.load(:submitter) |> Ash.Query.filter(id: knowledge.id)
      [loaded] = Ash.read!(query)

      assert loaded.submitter.name == "test-submitter"
    end

    test "loads contributions" do
      knowledge = insert(:knowledge)
      node = insert(:node)
      contribution = insert(:contribution, knowledge: knowledge, node: node)

      query = Knowledge |> Ash.Query.load(:contributions) |> Ash.Query.filter(id: knowledge.id)
      [loaded] = Ash.read!(query)

      assert length(loaded.contributions) == 1
      assert List.first(loaded.contributions).id == contribution.id
    end
  end
end
