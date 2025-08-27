defmodule XPando.Core.NodeTest do
  use XPando.DataCase

  import XPando.Factory

  alias XPando.Core.Node

  describe "create/1" do
    test "creates node with valid attributes" do
      attrs = %{
        name: "test-node",
        public_key: "valid_public_key_" <> String.duplicate("x", 50),
        private_key_hash: "hash123",
        node_signature: "signature123",
        endpoint: "https://test.example.com"
      }

      assert {:ok, node} = Node |> Ash.Changeset.for_create(:create, attrs) |> Ash.create()
      assert node.name == attrs.name
      assert node.status == :inactive
      assert node.reputation_score == Decimal.new("50.0")
    end

    test "fails with invalid public key" do
      attrs = %{
        name: "test-node",
        # Too short
        public_key: "short",
        private_key_hash: "hash123",
        node_signature: "signature123",
        endpoint: "https://test.example.com"
      }

      assert {:error, changeset} =
               Node |> Ash.Changeset.for_create(:create, attrs) |> Ash.create()

      assert changeset.errors != []
    end

    test "enforces unique public key" do
      node = insert(:node)

      attrs = %{
        name: "duplicate-node",
        public_key: node.public_key,
        private_key_hash: "different_hash",
        node_signature: "different_signature",
        endpoint: "https://different.example.com"
      }

      assert {:error, changeset} =
               Node |> Ash.Changeset.for_create(:create, attrs) |> Ash.create()

      assert changeset.errors != []
    end
  end

  describe "register/1" do
    test "registers node with active status" do
      attrs = %{
        name: "new-node",
        endpoint: "https://new.example.com",
        public_key: "valid_key_" <> String.duplicate("x", 50),
        signature: "valid_signature",
        private_key_hash: "hash123",
        node_signature: "signature123"
      }

      assert {:ok, node} = Node |> Ash.Changeset.for_create(:register, attrs) |> Ash.create()
      assert node.status == :active
      assert node.last_seen_at != nil
    end
  end

  describe "update_reputation/1" do
    test "updates reputation and validation counts" do
      node = insert(:node, reputation_score: Decimal.new("50.0"), total_validations: 5)

      attrs = %{
        new_reputation: Decimal.new("75.0"),
        validation_result: true
      }

      assert {:ok, updated_node} =
               node |> Ash.Changeset.for_update(:update_reputation, attrs) |> Ash.update()

      assert updated_node.reputation_score == Decimal.new("75.0")
      assert updated_node.total_validations == 6
      assert updated_node.successful_validations == 1
    end

    test "increments total validations for failed validation" do
      node = insert(:node, total_validations: 5, successful_validations: 3)

      attrs = %{
        new_reputation: Decimal.new("45.0"),
        validation_result: false
      }

      assert {:ok, updated_node} =
               node |> Ash.Changeset.for_update(:update_reputation, attrs) |> Ash.update()

      assert updated_node.total_validations == 6
      # Should not increment
      assert updated_node.successful_validations == 3
    end
  end

  describe "update_activity/1" do
    test "updates last seen and status" do
      node = insert(:node, status: :inactive, connection_count: 0)

      attrs = %{connections: 5}

      assert {:ok, updated_node} =
               node |> Ash.Changeset.for_update(:update_activity, attrs) |> Ash.update()

      assert updated_node.status == :active
      assert updated_node.connection_count == 5
      assert DateTime.diff(updated_node.last_seen_at, DateTime.utc_now()) < 5
    end
  end

  describe "list_active/0" do
    test "returns only active nodes" do
      active_node = insert(:node, status: :active)
      _inactive_node = insert(:node, status: :inactive)

      result = Node |> Ash.Query.for_read(:list_active) |> Ash.read!()

      assert length(result) == 1
      assert List.first(result).id == active_node.id
    end
  end

  describe "list_by_specialization/1" do
    test "returns nodes with matching specialization" do
      ai_node = insert(:node, specializations: ["ai", "machine_learning"])
      blockchain_node = insert(:node, specializations: ["blockchain", "crypto"])
      _other_node = insert(:node, specializations: ["web", "frontend"])

      query = Node |> Ash.Query.for_read(:list_by_specialization, %{specialization: "ai"})
      result = Ash.read!(query)

      node_ids = Enum.map(result, & &1.id)
      assert ai_node.id in node_ids
      refute blockchain_node.id in node_ids
    end
  end

  describe "list_high_reputation/1" do
    test "returns high reputation nodes in descending order" do
      high_rep_node = insert(:node, reputation_score: Decimal.new("90.0"))
      medium_rep_node = insert(:node, reputation_score: Decimal.new("70.0"))
      _low_rep_node = insert(:node, reputation_score: Decimal.new("30.0"))

      query =
        Node |> Ash.Query.for_read(:list_high_reputation, %{min_reputation: Decimal.new("75.0")})

      result = Ash.read!(query)

      assert length(result) == 1
      assert List.first(result).id == high_rep_node.id
    end
  end

  describe "calculations" do
    test "success_rate calculation" do
      node = insert(:node, total_validations: 10, successful_validations: 8)

      query = Node |> Ash.Query.load(:success_rate) |> Ash.Query.filter(id: node.id)
      [loaded_node] = Ash.read!(query)

      assert loaded_node.success_rate == Decimal.new("0.8")
    end

    test "success_rate with zero validations" do
      node = insert(:node, total_validations: 0, successful_validations: 0)

      query = Node |> Ash.Query.load(:success_rate) |> Ash.Query.filter(id: node.id)
      [loaded_node] = Ash.read!(query)

      assert loaded_node.success_rate == Decimal.new("0.0")
    end

    test "contribution_score calculation" do
      node = insert(:node, knowledge_contributions: 5, successful_validations: 10)

      query = Node |> Ash.Query.load(:contribution_score) |> Ash.Query.filter(id: node.id)
      [loaded_node] = Ash.read!(query)

      expected =
        Decimal.add(
          Decimal.mult(Decimal.new("5"), Decimal.new("10.0")),
          Decimal.mult(Decimal.new("10"), Decimal.new("5.0"))
        )

      assert loaded_node.contribution_score == expected
    end
  end

  describe "validations" do
    test "successful validations cannot exceed total validations" do
      attrs = %{
        name: "test-node",
        public_key: "valid_key_" <> String.duplicate("x", 50),
        private_key_hash: "hash123",
        node_signature: "signature123",
        endpoint: "https://test.example.com",
        total_validations: 5,
        # Invalid: more than total
        successful_validations: 10
      }

      assert {:error, changeset} =
               Node |> Ash.Changeset.for_create(:create, attrs) |> Ash.create()

      assert changeset.errors != []
    end

    test "reputation score must be non-negative" do
      attrs = %{
        name: "test-node",
        public_key: "valid_key_" <> String.duplicate("x", 50),
        private_key_hash: "hash123",
        node_signature: "signature123",
        endpoint: "https://test.example.com",
        # Invalid: negative
        reputation_score: Decimal.new("-10.0")
      }

      assert {:error, changeset} =
               Node |> Ash.Changeset.for_create(:create, attrs) |> Ash.create()

      assert changeset.errors != []
    end
  end

  describe "relationships" do
    test "loads contributed knowledge" do
      node = insert(:node)
      knowledge = insert(:knowledge, submitter: node)

      query = Node |> Ash.Query.load(:contributed_knowledge) |> Ash.Query.filter(id: node.id)
      [loaded_node] = Ash.read!(query)

      assert length(loaded_node.contributed_knowledge) == 1
      assert List.first(loaded_node.contributed_knowledge).id == knowledge.id
    end

    test "loads contributions" do
      node = insert(:node)
      knowledge = insert(:knowledge)
      contribution = insert(:contribution, node: node, knowledge: knowledge)

      query = Node |> Ash.Query.load(:contributions) |> Ash.Query.filter(id: node.id)
      [loaded_node] = Ash.read!(query)

      assert length(loaded_node.contributions) == 1
      assert List.first(loaded_node.contributions).id == contribution.id
    end
  end
end
