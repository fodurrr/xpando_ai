defmodule XPando.Core.UserTest do
  @moduledoc """
  Tests for the User resource including authentication functionality.
  """
  use XPando.DataCase, async: true
  alias XPando.Core.Node
  alias XPando.Core.User

  describe "User resource" do
    test "creates a user with valid attributes" do
      attrs = %{
        email: "test@example.com",
        password: "test123456"
      }

      assert {:ok, user} =
               User
               |> Ash.Changeset.for_create(:register_with_password, attrs)
               |> Ash.create(authorize?: false)

      assert to_string(user.email) == "test@example.com"
      assert user.role == :user
      assert user.hashed_password != "test123456"
      assert String.length(user.hashed_password) > 0
    end

    test "requires email to be present" do
      attrs = %{
        password: "test123456"
      }

      assert {:error, changeset} =
               User |> Ash.Changeset.for_create(:register_with_password, attrs) |> Ash.create()

      assert Enum.any?(changeset.errors, fn error ->
               error.field == :email and is_struct(error, Ash.Error.Changes.Required)
             end)
    end

    test "requires password to be present" do
      attrs = %{
        email: "test@example.com"
      }

      assert {:error, changeset} =
               User |> Ash.Changeset.for_create(:register_with_password, attrs) |> Ash.create()

      assert Enum.any?(changeset.errors, fn error ->
               error.field == :password and is_struct(error, Ash.Error.Changes.Required)
             end)
    end

    test "validates email format" do
      attrs = %{
        email: "invalid_email",
        password: "test123456"
      }

      assert {:error, changeset} =
               User |> Ash.Changeset.for_create(:register_with_password, attrs) |> Ash.create()

      assert Enum.any?(changeset.errors, fn error ->
               error.field == :email and is_struct(error, Ash.Error.Changes.InvalidAttribute)
             end)
    end

    test "ensures email uniqueness" do
      attrs = %{
        email: "test@example.com",
        password: "test123456"
      }

      assert {:ok, _user1} =
               User
               |> Ash.Changeset.for_create(:register_with_password, attrs)
               |> Ash.create(authorize?: false)

      assert {:error, changeset} =
               User
               |> Ash.Changeset.for_create(:register_with_password, attrs)
               |> Ash.create(authorize?: false)

      assert Enum.any?(changeset.errors, fn error ->
               error.field == :email and is_struct(error, Ash.Error.Changes.InvalidAttribute)
             end)
    end

    test "supports different user roles" do
      for role <- [:user, :node_operator, :admin] do
        attrs = %{
          email: "test_#{role}@example.com",
          password: "test123456",
          role: role
        }

        assert {:ok, user} =
                 User
                 |> Ash.Changeset.for_create(:register_with_password, attrs)
                 |> Ash.create(authorize?: false)

        assert user.role == role
      end
    end
  end

  describe "User authentication" do
    setup do
      attrs = %{
        email: "auth_test@example.com",
        password: "test123456",
        role: :user
      }

      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, attrs)
        |> Ash.create(authorize?: false)

      %{user: user}
    end

    test "can sign in with valid credentials", %{user: user} do
      strategy = AshAuthentication.Info.strategy!(User, :password)

      assert {:ok, signed_in_user} =
               AshAuthentication.Strategy.action(strategy, :sign_in, %{
                 email: user.email,
                 password: "test123456"
               })

      assert signed_in_user.id == user.id
    end

    test "cannot sign in with invalid password", %{user: user} do
      strategy = AshAuthentication.Info.strategy!(User, :password)

      assert {:error, _error} =
               AshAuthentication.Strategy.action(strategy, :sign_in, %{
                 email: user.email,
                 password: "wrong_password"
               })
    end

    test "cannot sign in with invalid email" do
      strategy = AshAuthentication.Info.strategy!(User, :password)

      assert {:error, _error} =
               AshAuthentication.Strategy.action(strategy, :sign_in, %{
                 email: "nonexistent@example.com",
                 password: "test123456"
               })
    end
  end

  describe "User-Node relationships" do
    setup do
      user_attrs = %{
        email: "node_operator@example.com",
        password: "test123456",
        role: :node_operator
      }

      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, user_attrs)
        |> Ash.create(authorize?: false)

      # Create valid Ed25519 key pair and proper signature for testing
      endpoint = "http://localhost:8080"
      identity = XPando.DataCase.generate_valid_node_identity(endpoint)

      node_attrs = %{
        name: "Test Node",
        endpoint: endpoint,
        public_key: identity.public_key,
        signature: identity.signature
      }

      {:ok, node} =
        Node |> Ash.Changeset.for_create(:register, node_attrs) |> Ash.create(actor: user)

      %{user: user, node: node}
    end

    test "can associate user with node", %{user: user, node: node} do
      {:ok, updated_user} =
        user |> Ash.Changeset.for_update(:update, %{node_id: node.id}) |> Ash.update(actor: user)

      assert updated_user.node_id == node.id
    end

    test "node operator role allows node management", %{user: user} do
      assert user.role == :node_operator
      # Additional role-based authorization tests would go here
    end
  end

  describe "User authorization policies" do
    setup do
      user_attrs = %{
        email: "policy_test@example.com",
        password: "test123456",
        role: :user
      }

      admin_attrs = %{
        email: "admin@example.com",
        password: "admin123456",
        role: :admin
      }

      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, user_attrs)
        |> Ash.create(authorize?: false)

      {:ok, admin} =
        User
        |> Ash.Changeset.for_create(:register_with_password, admin_attrs)
        |> Ash.create(authorize?: false)

      %{user: user, admin: admin}
    end

    test "user can read their own data", %{user: user} do
      assert {:ok, read_user} =
               User
               |> Ash.Query.for_read(:read)
               |> Ash.Query.filter(id == ^user.id)
               |> Ash.read_one(actor: user)

      assert read_user.id == user.id
    end

    test "admin can read all user data", %{user: user, admin: admin} do
      assert {:ok, read_user} =
               User
               |> Ash.Query.for_read(:read)
               |> Ash.Query.filter(id == ^user.id)
               |> Ash.read_one(actor: admin)

      assert read_user.id == user.id
    end

    test "user can update their own data", %{user: user} do
      assert {:ok, _updated_user} =
               user |> Ash.Changeset.for_update(:update, %{}, actor: user) |> Ash.update()
    end

    test "admin can update any user data", %{user: user, admin: admin} do
      assert {:ok, _updated_user} =
               user |> Ash.Changeset.for_update(:update, %{}, actor: admin) |> Ash.update()
    end
  end

  describe "Token management" do
    setup do
      attrs = %{
        email: "token_test@example.com",
        password: "test123456",
        role: :user
      }

      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, attrs)
        |> Ash.create(authorize?: false)

      %{user: user}
    end

    test "generates tokens on successful authentication", %{user: user} do
      strategy = AshAuthentication.Info.strategy!(User, :password)

      {:ok, signed_in_user} =
        AshAuthentication.Strategy.action(strategy, :sign_in, %{
          email: user.email,
          password: "test123456"
        })

      assert signed_in_user.id == user.id
      # Token would be in metadata or generated separately
      # For now, just verify sign-in works
    end

    test "validates tokens properly", %{user: user} do
      strategy = AshAuthentication.Info.strategy!(User, :password)

      {:ok, signed_in_user} =
        AshAuthentication.Strategy.action(strategy, :sign_in, %{
          email: user.email,
          password: "test123456"
        })

      assert signed_in_user.id == user.id

      # Generate a JWT token for the user
      {:ok, token, claims} = AshAuthentication.Jwt.token_for_user(signed_in_user)
      assert is_binary(token)
      assert String.length(token) > 0

      # Verify the token claims
      assert claims["sub"] =~ to_string(signed_in_user.id)

      # Verify the token can be validated
      {:ok, verified_claims, _user} = AshAuthentication.Jwt.verify(token, User)
      assert verified_claims["sub"] =~ to_string(signed_in_user.id)
    end
  end

  describe "Authorization policies" do
    setup do
      user_attrs = %{
        email: "policy_user@example.com",
        password: "test123456",
        role: :user
      }

      admin_attrs = %{
        email: "policy_admin@example.com",
        password: "admin123456",
        role: :admin
      }

      # Create users with authorization bypassed for setup only
      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, user_attrs)
        |> Ash.create(authorize?: false)

      {:ok, admin} =
        User
        |> Ash.Changeset.for_create(:register_with_password, admin_attrs)
        |> Ash.create(authorize?: false)

      %{user: user, admin: admin}
    end

    test "regular users can read their own profile", %{user: user} do
      assert {:ok, users} =
               User
               |> Ash.Query.for_read(:read)
               |> Ash.read(actor: user, authorize?: true)

      # User should only see their own profile
      assert length(users) == 1
      found_user = hd(users)
      assert found_user.id == user.id
    end

    test "users cannot read other users' profiles", %{user: user, admin: admin} do
      # When user tries to read all profiles, they should only see their own
      assert {:ok, users} =
               User
               |> Ash.Query.for_read(:read)
               |> Ash.read(actor: user, authorize?: true)

      # Should only contain the user's own profile, not the admin's
      user_ids = Enum.map(users, & &1.id)
      assert user.id in user_ids
      refute admin.id in user_ids
      assert length(users) == 1
    end

    test "admin users can read any profile", %{user: user, admin: admin} do
      assert {:ok, users} =
               User
               |> Ash.Query.for_read(:read)
               |> Ash.read(actor: admin, authorize?: true)

      user_ids = Enum.map(users, & &1.id)
      assert user.id in user_ids
      assert admin.id in user_ids
    end

    test "unauthenticated requests are forbidden" do
      # No actor provided - should be forbidden
      assert {:error, error} =
               User
               |> Ash.Query.for_read(:read)
               |> Ash.read(authorize?: true)

      assert %Ash.Error.Forbidden{} = error
    end

    test "user registration through authorized action works" do
      # Test user registration with authorization enabled
      attrs = %{
        email: "authorized_test@example.com",
        password: "test123456",
        role: :user
      }

      # Registration should work even with authorization enabled (special case)
      assert {:ok, user} =
               User
               |> Ash.Changeset.for_create(:register_with_password, attrs)
               |> Ash.create(authorize?: true)

      assert to_string(user.email) == "authorized_test@example.com"
      assert user.role == :user
    end
  end
end
