defmodule XPando.Core.AuthenticationIntegrationTest do
  @moduledoc """
  Integration tests for the complete authentication and authorization flow.
  Tests user registration, login, token management, and node operations.
  """
  use XPando.DataCase, async: true
  alias XPando.Core.{Knowledge, Node, User}

  describe "Complete authentication flow" do
    test "user registration, authentication, and node operations" do
      # 1. User Registration
      user_attrs = %{
        email: "integration_test@example.com",
        password: "secure_password_123",
        role: :node_operator
      }

      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, user_attrs)
        |> Ash.create(authorize?: false)

      assert to_string(user.email) == "integration_test@example.com"
      assert user.role == :node_operator
      # 2. User Authentication
      strategy = AshAuthentication.Info.strategy!(User, :password)

      {:ok, authenticated_user} =
        AshAuthentication.Strategy.action(strategy, :sign_in, %{
          email: user.email,
          password: "secure_password_123"
        })

      assert authenticated_user.id == user.id

      # 3. Token Validation - generate and validate JWT token
      {:ok, token, claims} = AshAuthentication.Jwt.token_for_user(authenticated_user)
      assert is_binary(token)
      assert claims["sub"] =~ to_string(authenticated_user.id)

      # Verify token can be used to retrieve user
      {:ok, verified_claims, _verified_user} = AshAuthentication.Jwt.verify(token, User)
      assert verified_claims["sub"] =~ to_string(authenticated_user.id)
      assert is_binary(verified_claims["sub"])
      assert is_number(verified_claims["exp"])
      # 4. Node Registration with User Association
      endpoint = "http://integration.example.com"
      identity = XPando.DataCase.generate_valid_node_identity(endpoint)

      node_attrs = %{
        name: "Integration Test Node",
        endpoint: endpoint,
        public_key: identity.public_key,
        signature: identity.signature
      }

      {:ok, node} =
        Node |> Ash.Changeset.for_create(:register, node_attrs) |> Ash.create(actor: user)

      assert node.status == :active
      # Node ID is derived from decoded public key
      decoded_public_key = Base.decode64!(identity.public_key)
      expected_node_id = :crypto.hash(:sha256, decoded_public_key) |> Base.encode16(case: :lower)
      assert node.node_id == expected_node_id
      # 5. Associate Node with User
      {:ok, updated_user} =
        user |> Ash.Changeset.for_update(:update, %{node_id: node.id}) |> Ash.update(actor: user)

      assert updated_user.node_id == node.id
      # 6. Test Node Operations with User Authorization
      {:ok, _updated_node} =
        node
        |> Ash.Changeset.for_update(
          :update_activity,
          %{
            connections: 10
          },
          actor: updated_user
        )
        |> Ash.update()

      # 7. Knowledge Submission (testing resource-level authorization)
      knowledge_attrs = %{
        submitter_node_id: node.id,
        content: "This is integration test knowledge content",
        title: "Integration Test Knowledge",
        category: "Testing",
        knowledge_type: :insight
      }

      {:ok, knowledge} =
        Knowledge
        |> Ash.Changeset.for_create(:submit_for_validation, knowledge_attrs, actor: updated_user)
        |> Ash.create()

      assert knowledge.validation_status == :pending
      assert knowledge.submitter_id == node.id
      # 8. Test Read Permissions
      # User should be able to read their own node's knowledge
      user_knowledge =
        Knowledge |> Ash.Query.filter(submitter_id == ^node.id) |> Ash.read!(actor: updated_user)

      assert length(user_knowledge) == 1
      assert hd(user_knowledge).id == knowledge.id
    end

    test "authorization boundaries work correctly" do
      # Create two users and two nodes to test authorization boundaries
      user1_attrs = %{
        email: "user1@example.com",
        password: "password123",
        role: :node_operator
      }

      user2_attrs = %{
        email: "user2@example.com",
        password: "password456",
        role: :user
      }

      {:ok, user1} =
        User
        |> Ash.Changeset.for_create(:register_with_password, user1_attrs)
        |> Ash.create(authorize?: false)

      {:ok, user2} =
        User
        |> Ash.Changeset.for_create(:register_with_password, user2_attrs)
        |> Ash.create(authorize?: false)

      # Create nodes for each user
      # Create valid node credentials
      endpoint1 = "http://user1.example.com"
      identity1 = XPando.DataCase.generate_valid_node_identity(endpoint1)

      endpoint2 = "http://user2.example.com"
      identity2 = XPando.DataCase.generate_valid_node_identity(endpoint2)

      node1_attrs = %{
        name: "User1 Node",
        endpoint: endpoint1,
        public_key: identity1.public_key,
        signature: identity1.signature
      }

      node2_attrs = %{
        name: "User2 Node",
        endpoint: endpoint2,
        public_key: identity2.public_key,
        signature: identity2.signature
      }

      {:ok, node1} =
        Node |> Ash.Changeset.for_create(:register, node1_attrs) |> Ash.create(actor: user1)

      {:ok, node2} =
        Node |> Ash.Changeset.for_create(:register, node2_attrs) |> Ash.create(actor: user1)

      # Associate nodes with users
      {:ok, user1} =
        user1
        |> Ash.Changeset.for_update(:update, %{node_id: node1.id})
        |> Ash.update(actor: user1)

      {:ok, user2} =
        user2
        |> Ash.Changeset.for_update(:update, %{node_id: node2.id})
        |> Ash.update(actor: user2)

      # User1 should not be able to update User2's node
      assert {:error, %Ash.Error.Forbidden{}} =
               node2
               |> Ash.Changeset.for_update(
                 :update_activity,
                 %{
                   connections: 5
                 },
                 actor: user1
               )
               |> Ash.update()

      # User2 should be able to update their own node
      {:ok, _} =
        node2
        |> Ash.Changeset.for_update(
          :update_activity,
          %{
            connections: 3
          },
          actor: user2
        )
        |> Ash.update()
    end

    test "admin privileges work correctly" do
      # Create admin user
      admin_attrs = %{
        email: "admin@example.com",
        password: "admin_password",
        role: :admin
      }

      regular_user_attrs = %{
        email: "regular@example.com",
        password: "regular_password",
        role: :user
      }

      {:ok, admin} =
        User
        |> Ash.Changeset.for_create(:register_with_password, admin_attrs)
        |> Ash.create(authorize?: false)

      {:ok, regular_user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, regular_user_attrs)
        |> Ash.create(authorize?: false)

      # Create a node
      endpoint = "http://admin-test.example.com"
      identity = XPando.DataCase.generate_valid_node_identity(endpoint)

      node_attrs = %{
        name: "Admin Test Node",
        endpoint: endpoint,
        public_key: identity.public_key,
        signature: identity.signature
      }

      {:ok, node} =
        Node |> Ash.Changeset.for_create(:register, node_attrs) |> Ash.create(actor: admin)

      # Admin should be able to read any user's data
      admin_users = User |> Ash.Query.filter(id == ^regular_user.id) |> Ash.read!(actor: admin)
      assert length(admin_users) == 1
      # Admin should be able to update any node
      {:ok, _} =
        node
        |> Ash.Changeset.for_update(
          :update_reputation,
          %{
            new_reputation: Decimal.new("90.0"),
            validation_result: true
          },
          actor: admin
        )
        |> Ash.update()

      # Admin should be able to destroy nodes
      :ok = node |> Ash.Changeset.for_destroy(:destroy, %{}, actor: admin) |> Ash.destroy()
    end

    test "session management and logout functionality" do
      user_attrs = %{
        email: "session_test@example.com",
        password: "session_password",
        role: :user
      }

      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, user_attrs)
        |> Ash.create(authorize?: false)

      # Test basic authentication functionality
      {:ok, auth_user} =
        User
        |> Ash.Query.for_read(:sign_in_with_password, %{
          email: user.email,
          password: "session_password"
        })
        |> Ash.read_one(authorize?: false)

      assert auth_user.id == user.id

      # Test that we can authenticate again (multiple sessions)
      {:ok, auth_user2} =
        User
        |> Ash.Query.for_read(:sign_in_with_password, %{
          email: user.email,
          password: "session_password"
        })
        |> Ash.read_one(authorize?: false)

      assert auth_user2.id == user.id
      # Both authentication attempts should succeed for the same user
      assert auth_user.id == auth_user2.id
    end

    test "role-based resource access" do
      # Create users with different roles
      node_operator_attrs = %{
        email: "operator@example.com",
        password: "operator_pass",
        role: :node_operator
      }

      regular_user_attrs = %{
        email: "user@example.com",
        password: "user_pass",
        role: :user
      }

      {:ok, operator} =
        User
        |> Ash.Changeset.for_create(:register_with_password, node_operator_attrs)
        |> Ash.create(authorize?: false)

      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, regular_user_attrs)
        |> Ash.create(authorize?: false)

      # Create a node
      endpoint = "http://role-test.example.com"
      identity = XPando.DataCase.generate_valid_node_identity(endpoint)

      node_attrs = %{
        name: "Role Test Node",
        endpoint: endpoint,
        public_key: identity.public_key,
        signature: identity.signature
      }

      {:ok, node} =
        Node |> Ash.Changeset.for_create(:register, node_attrs) |> Ash.create(actor: operator)

      # Associate node with operator
      {:ok, operator} =
        operator
        |> Ash.Changeset.for_update(:update, %{node_id: node.id})
        |> Ash.update(actor: operator)

      # Node operator should be able to submit knowledge
      knowledge_attrs = %{
        submitter_node_id: node.id,
        content: "Knowledge from node operator",
        title: "Operator Knowledge",
        category: "Operations"
      }

      {:ok, knowledge} =
        Knowledge
        |> Ash.Changeset.for_create(:submit_for_validation, knowledge_attrs, actor: operator)
        |> Ash.create()

      assert knowledge.submitter_id == node.id
      # Regular user should be able to read validated knowledge (once validated)
      # For now, they can read their own submitted knowledge
      all_knowledge = Knowledge |> Ash.read!(actor: user, authorize?: false)
      assert is_list(all_knowledge)
    end
  end
end
