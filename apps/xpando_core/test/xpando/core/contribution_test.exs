defmodule XPando.Core.ContributionTest do
  use XPando.DataCase

  describe "Contribution resource" do
    test "can create contribution using fast_contribution" do
      contribution = fast_contribution()
      assert contribution.id
      assert contribution.node_id
      assert contribution.knowledge_id
      assert contribution.contribution_type
      assert contribution.quality_score
      assert contribution.contribution_status == :active
    end

    test "can create contribution with specific node and knowledge" do
      node = fast_node()
      knowledge = fast_knowledge()

      contribution =
        fast_contribution(%{
          node_id: node.id,
          knowledge_id: knowledge.id,
          contribution_type: :validation,
          quality_score: Decimal.new("9.5")
        })

      assert contribution.node_id == node.id
      assert contribution.knowledge_id == knowledge.id
      assert contribution.contribution_type == :validation
      assert Decimal.eq?(contribution.quality_score, Decimal.new("9.5"))
    end

    test "contribution has default values set correctly" do
      contribution = fast_contribution()
      assert contribution.contribution_status == :active
      assert contribution.peer_reviews == 0
      assert contribution.positive_reviews == 0
      assert contribution.impact_score
      assert contribution.contribution_data
    end

    test "can read contributions" do
      contribution = fast_contribution()
      found_contributions = Ash.read!(XPando.Core.Contribution, domain: XPando.Core)
      contribution_ids = Enum.map(found_contributions, & &1.id)
      assert contribution.id in contribution_ids
    end

    test "can filter contributions by type" do
      validation_contribution = fast_contribution(%{contribution_type: :validation})

      query =
        XPando.Core.Contribution
        |> Ash.Query.filter(contribution_type == :validation)

      contributions = Ash.read!(query, domain: XPando.Core)
      contribution_ids = Enum.map(contributions, & &1.id)
      assert validation_contribution.id in contribution_ids
    end

    test "can filter contributions by status" do
      active_contribution = fast_contribution(%{contribution_status: :active})

      query =
        XPando.Core.Contribution
        |> Ash.Query.filter(contribution_status == :active)

      contributions = Ash.read!(query, domain: XPando.Core)
      contribution_ids = Enum.map(contributions, & &1.id)
      assert active_contribution.id in contribution_ids
    end

    test "can create multiple contributions for same knowledge" do
      knowledge = fast_knowledge()
      node1 = fast_node()
      node2 = fast_node()
      contrib1 = fast_contribution(%{node_id: node1.id, knowledge_id: knowledge.id})
      contrib2 = fast_contribution(%{node_id: node2.id, knowledge_id: knowledge.id})
      assert contrib1.knowledge_id == knowledge.id
      assert contrib2.knowledge_id == knowledge.id
      assert contrib1.node_id != contrib2.node_id
    end
  end
end
