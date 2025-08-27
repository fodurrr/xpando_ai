defmodule XPando.Core.NodeTest do
  use XPando.DataCase

  describe "Node resource" do
    test "can create node using fast_node" do
      node = fast_node()

      assert node.id
      assert node.name
      assert node.status == :active
      assert node.public_key
      assert node.endpoint
      assert String.contains?(node.endpoint, "xpando.network")
    end

    test "can create multiple unique nodes" do
      node1 = fast_node(%{name: "node-1"})
      node2 = fast_node(%{name: "node-2"})

      assert node1.name == "node-1"
      assert node2.name == "node-2"
      assert node1.id != node2.id
      assert node1.endpoint != node2.endpoint
    end

    test "node has default values set correctly" do
      node = fast_node()

      assert node.status == :active
      assert node.expertise_level
      assert node.reputation_score
      assert node.trust_rating
      assert node.validation_accuracy
      assert node.region
    end

    test "can read nodes" do
      node = fast_node()

      found_nodes = Ash.read!(XPando.Core.Node, domain: XPando.Core)
      node_ids = Enum.map(found_nodes, & &1.id)

      assert node.id in node_ids
    end

    test "can filter nodes by status" do
      active_node = fast_node(%{status: :active})

      query =
        XPando.Core.Node
        |> Ash.Query.filter(status == :active)

      nodes = Ash.read!(query, domain: XPando.Core)
      node_ids = Enum.map(nodes, & &1.id)

      assert active_node.id in node_ids
    end
  end
end
