defmodule XPando.Core.NodeTest do
  use XPando.DataCase
  alias XPando.Core.Node
  alias XPando.Core.User

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

  describe "Node identity system" do
    setup do
      # Create a node operator user for node creation
      user_attrs = %{
        email: "node_identity@example.com",
        password: "test123456",
        role: :node_operator
      }

      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, user_attrs)
        |> Ash.create(authorize?: false)

      %{user: user}
    end

    test "generates unique node_id from public key", %{user: user} do
      endpoint = "http://identity-test.example.com"
      identity = XPando.DataCase.generate_valid_node_identity(endpoint)

      attrs = %{
        name: "Identity Test Node",
        endpoint: endpoint,
        public_key: identity.public_key,
        signature: identity.signature
      }

      {:ok, node} = Node |> Ash.Changeset.for_create(:register, attrs) |> Ash.create(actor: user)

      # Node ID should be SHA-256 hash of public key (binary, not base64)
      expected_node_id =
        :crypto.hash(:sha256, Base.decode64!(identity.public_key)) |> Base.encode16(case: :lower)

      assert node.node_id == expected_node_id
    end

    test "enforces unique node_id across network", %{user: user} do
      # Generate valid identity for first node
      endpoint1 = "http://first.example.com"
      identity1 = XPando.DataCase.generate_valid_node_identity(endpoint1)

      attrs = %{
        name: "First Node",
        endpoint: endpoint1,
        public_key: identity1.public_key,
        signature: identity1.signature
      }

      {:ok, _node1} =
        Node |> Ash.Changeset.for_create(:register, attrs) |> Ash.create(actor: user)

      # Attempt to register another node with same public key (different signature)
      endpoint2 = "http://second.example.com"
      identity2 = XPando.DataCase.generate_valid_node_identity(endpoint2)

      attrs2 = %{
        name: "Second Node",
        endpoint: endpoint2,
        # Same public key = same node_id
        public_key: identity1.public_key,
        # Different signature (invalid)
        signature: identity2.signature
      }

      assert {:error, _changeset} =
               Node |> Ash.Changeset.for_create(:register, attrs2) |> Ash.create(actor: user)
    end

    test "validates node identity during registration", %{user: user} do
      endpoint = "http://validation-test.example.com"
      identity = XPando.DataCase.generate_valid_node_identity(endpoint)

      attrs = %{
        name: "Validation Test Node",
        endpoint: endpoint,
        public_key: identity.public_key,
        signature: identity.signature
      }

      # Should succeed with valid signature
      {:ok, node} = Node |> Ash.Changeset.for_create(:register, attrs) |> Ash.create(actor: user)
      assert node.status == :active
    end
  end

  describe "Node-User relationships" do
    setup do
      user_attrs = %{
        email: "node_owner@example.com",
        password: "test123456"
      }

      user =
        User
        |> Ash.Changeset.for_create(:register_with_password, user_attrs)
        |> Ash.create!(authorize?: false)

      # Update user role separately if needed
      user =
        user
        |> Ash.Changeset.for_update(:update, %{role: :node_operator})
        |> Ash.update!(authorize?: false)

      endpoint = "http://users-node.example.com"
      identity = XPando.DataCase.generate_valid_node_identity(endpoint)

      node_attrs = %{
        name: "User's Node",
        endpoint: endpoint,
        public_key: identity.public_key,
        signature: identity.signature
      }

      {:ok, node} =
        Node |> Ash.Changeset.for_create(:register, node_attrs) |> Ash.create(actor: user)

      %{user: user, node: node}
    end

    test "node can be associated with user", %{user: user, node: node} do
      # Associate node with user
      {:ok, updated_user} =
        user
        |> Ash.Changeset.for_update(:update, %{node_id: node.id})
        |> Ash.update(authorize?: false)

      assert updated_user.node_id == node.id
      # Load relationship
      user_with_node =
        User
        |> Ash.Query.load(:node)
        |> Ash.Query.filter(id == ^user.id)
        |> Ash.read_one!(actor: user)

      assert user_with_node.node.id == node.id
    end

    test "node authorization works with user relationship", %{user: user, node: node} do
      # Associate node with user
      {:ok, _updated_user} =
        user |> Ash.Changeset.for_update(:update, %{node_id: node.id}) |> Ash.update(actor: user)

      # User should be able to update their node
      {:ok, _updated_node} =
        node
        |> Ash.Changeset.for_update(:update_activity, %{connections: 5}, actor: user)
        |> Ash.update()
    end
  end

  describe "Node authorization policies" do
    setup do
      user_attrs = %{
        email: "policy_node_test@example.com",
        password: "test123456"
      }

      admin_attrs = %{
        email: "admin_node@example.com",
        password: "admin123456"
      }

      user =
        User
        |> Ash.Changeset.for_create(:register_with_password, user_attrs)
        |> Ash.create!(authorize?: false)

      admin =
        User
        |> Ash.Changeset.for_create(:register_with_password, admin_attrs)
        |> Ash.create!(authorize?: false)

      # Update roles separately
      user =
        user
        |> Ash.Changeset.for_update(:update, %{role: :node_operator})
        |> Ash.update!(authorize?: false)

      admin =
        admin
        |> Ash.Changeset.for_update(:update, %{role: :admin})
        |> Ash.update!(authorize?: false)

      endpoint = "http://policy-test.example.com"
      identity = XPando.DataCase.generate_valid_node_identity(endpoint)

      node_attrs = %{
        name: "Policy Test Node",
        endpoint: endpoint,
        public_key: identity.public_key,
        signature: identity.signature
      }

      {:ok, node} =
        Node |> Ash.Changeset.for_create(:register, node_attrs) |> Ash.create(actor: user)

      %{user: user, admin: admin, node: node}
    end

    test "anyone can read public node information", %{node: node} do
      nodes = Node |> Ash.Query.for_read(:read) |> Ash.Query.filter(id == ^node.id) |> Ash.read!()
      assert length(nodes) == 1
      assert hd(nodes).id == node.id
    end

    test "admin can update any node", %{admin: admin, node: node} do
      # First, do a failed validation to set up proper counts
      {:ok, node} =
        node
        |> Ash.Changeset.for_update(
          :update_reputation,
          %{
            new_reputation: Decimal.new("60.0"),
            validation_result: false
          },
          actor: admin
        )
        |> Ash.update()

      # Now do a successful validation
      {:ok, _updated_node} =
        node
        |> Ash.Changeset.for_update(
          :update_reputation,
          %{
            new_reputation: Decimal.new("75.0"),
            validation_result: true
          },
          actor: admin
        )
        |> Ash.update()
    end

    test "admin can delete nodes", %{admin: admin, node: node} do
      :ok = node |> Ash.Changeset.for_destroy(:destroy, %{}, actor: admin) |> Ash.destroy()
    end

    test "regular users cannot delete nodes", %{user: user, node: node} do
      assert {:error, %Ash.Error.Forbidden{}} =
               node |> Ash.Changeset.for_destroy(:destroy, %{}, actor: user) |> Ash.destroy()
    end
  end

  describe "Node authorization policies with authentication enabled" do
    setup do
      user_attrs = %{
        email: "node_auth_user@example.com",
        password: "test123456",
        role: :node_operator
      }

      regular_user_attrs = %{
        email: "regular_auth_user@example.com",
        password: "test123456",
        role: :user
      }

      admin_attrs = %{
        email: "admin_auth_user@example.com",
        password: "admin123456",
        role: :admin
      }

      {:ok, node_operator} =
        User
        |> Ash.Changeset.for_create(:register_with_password, user_attrs)
        |> Ash.create(authorize?: false)

      {:ok, regular_user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, regular_user_attrs)
        |> Ash.create(authorize?: false)

      {:ok, admin} =
        User
        |> Ash.Changeset.for_create(:register_with_password, admin_attrs)
        |> Ash.create(authorize?: false)

      %{node_operator: node_operator, regular_user: regular_user, admin: admin}
    end

    test "node operators can register nodes with authorization enabled", %{
      node_operator: node_operator
    } do
      endpoint = "http://auth-test.example.com"
      identity = XPando.DataCase.generate_valid_node_identity(endpoint)

      node_attrs = %{
        name: "Auth Test Node",
        endpoint: endpoint,
        public_key: identity.public_key,
        signature: identity.signature
      }

      # Node registration should work with proper authorization
      assert {:ok, node} =
               Node
               |> Ash.Changeset.for_create(:register, node_attrs)
               |> Ash.create(actor: node_operator, authorize?: true)

      assert node.name == "Auth Test Node"
      assert node.endpoint == endpoint
    end

    test "regular users cannot register nodes", %{regular_user: regular_user} do
      endpoint = "http://forbidden-test.example.com"
      identity = XPando.DataCase.generate_valid_node_identity(endpoint)

      node_attrs = %{
        name: "Forbidden Node",
        endpoint: endpoint,
        public_key: identity.public_key,
        signature: identity.signature
      }

      # Regular users should not be able to register nodes
      assert {:error, error} =
               Node
               |> Ash.Changeset.for_create(:register, node_attrs)
               |> Ash.create(actor: regular_user, authorize?: true)

      assert %Ash.Error.Forbidden{} = error
    end

    test "admins can read all nodes", %{admin: admin, node_operator: node_operator} do
      # Create a test node first
      endpoint = "http://admin-read-test.example.com"
      identity = XPando.DataCase.generate_valid_node_identity(endpoint)

      node_attrs = %{
        name: "Admin Read Test Node",
        endpoint: endpoint,
        public_key: identity.public_key,
        signature: identity.signature
      }

      {:ok, _node} =
        Node
        |> Ash.Changeset.for_create(:register, node_attrs)
        |> Ash.create(actor: node_operator)

      # Admin should be able to read all nodes
      assert {:ok, nodes} =
               Node
               |> Ash.Query.for_read(:read)
               |> Ash.read(actor: admin, authorize?: true)

      assert is_list(nodes)
      assert length(nodes) >= 1
    end

    test "node operators can read public node information", %{node_operator: node_operator} do
      # Create a test node owned by the node operator
      endpoint = "http://operator-read-test.example.com"
      identity = XPando.DataCase.generate_valid_node_identity(endpoint)

      node_attrs = %{
        name: "Operator Read Test Node",
        endpoint: endpoint,
        public_key: identity.public_key,
        signature: identity.signature
      }

      {:ok, owned_node} =
        Node
        |> Ash.Changeset.for_create(:register, node_attrs)
        |> Ash.create(actor: node_operator)

      # Node operator should be able to read public node information
      assert {:ok, nodes} =
               Node
               |> Ash.Query.for_read(:read)
               |> Ash.read(actor: node_operator, authorize?: true)

      assert is_list(nodes)
      # Should find the created node in the list
      node_ids = Enum.map(nodes, & &1.id)
      assert owned_node.id in node_ids
    end

    test "unauthenticated access allows reading public node info" do
      # No actor provided - should allow reading public info
      assert {:ok, nodes} =
               Node
               |> Ash.Query.for_read(:read)
               |> Ash.read(authorize?: true)

      assert is_list(nodes)
    end

    test "multiple operators can create nodes independently", %{node_operator: node_operator} do
      # Create two different node operators
      other_operator_attrs = %{
        email: "other_node_operator@example.com",
        password: "test123456",
        role: :node_operator
      }

      {:ok, other_operator} =
        User
        |> Ash.Changeset.for_create(:register_with_password, other_operator_attrs)
        |> Ash.create(authorize?: false)

      # First operator creates a node
      endpoint1 = "http://operator1-node.example.com"
      identity1 = XPando.DataCase.generate_valid_node_identity(endpoint1)

      node_attrs1 = %{
        name: "Operator 1 Node",
        endpoint: endpoint1,
        public_key: identity1.public_key,
        signature: identity1.signature
      }

      {:ok, node1} =
        Node
        |> Ash.Changeset.for_create(:register, node_attrs1)
        |> Ash.create(actor: node_operator)

      # Second operator creates a node
      endpoint2 = "http://operator2-node.example.com"
      identity2 = XPando.DataCase.generate_valid_node_identity(endpoint2)

      node_attrs2 = %{
        name: "Operator 2 Node",
        endpoint: endpoint2,
        public_key: identity2.public_key,
        signature: identity2.signature
      }

      {:ok, node2} =
        Node
        |> Ash.Changeset.for_create(:register, node_attrs2)
        |> Ash.create(actor: other_operator)

      # Both nodes should be visible in public listing
      {:ok, nodes} =
        Node
        |> Ash.Query.for_read(:read)
        |> Ash.read(authorize?: true)

      node_ids = Enum.map(nodes, & &1.id)
      assert node1.id in node_ids
      assert node2.id in node_ids
    end
  end
end
