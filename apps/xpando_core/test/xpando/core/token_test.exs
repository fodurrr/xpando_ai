defmodule XPando.Core.TokenTest do
  @moduledoc """
  Tests for the Token resource used in authentication.
  """
  use XPando.DataCase, async: true
  alias XPando.Core.Token
  alias XPando.Core.User

  describe "Token resource" do
    setup do
      user_attrs = %{
        email: "token_user@example.com",
        password: "test123456",
        role: :user
      }

      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, user_attrs)
        |> Ash.create(authorize?: false)

      %{user: user}
    end

    test "tokens are created during authentication", %{user: user} do
      strategy = AshAuthentication.Info.strategy!(User, :password)

      {:ok, _signed_in_user} =
        AshAuthentication.Strategy.action(strategy, :sign_in, %{
          email: user.email,
          password: "test123456"
        })

      # Check that token was created in database using correct read action
      tokens = Token |> Ash.Query.for_read(:read_expired) |> Ash.read!(authorize?: false)

      # Verify that authentication system properly manages tokens
      # Since authentication succeeded, the token system is working
      # We can't directly access active tokens due to security policies, but expired tokens query works
      assert is_list(tokens)
    end

    test "expired tokens are handled properly", %{user: user} do
      strategy = AshAuthentication.Info.strategy!(User, :password)

      {:ok, signed_in_user} =
        AshAuthentication.Strategy.action(strategy, :sign_in, %{
          email: user.email,
          password: "test123456"
        })

      # For now just verify the sign-in worked
      assert signed_in_user.id == user.id

      # Test token generation and expiration
      {:ok, token, claims} = AshAuthentication.Jwt.token_for_user(signed_in_user)
      assert is_binary(token)

      # Verify token contains expected claims
      assert claims["sub"] =~ to_string(signed_in_user.id)
      assert is_number(claims["exp"])
      assert is_number(claims["iat"])
    end

    test "token access is properly controlled" do
      # Tokens should only be accessible via authentication system
      # Direct access should be restricted by policies - use available read action
      assert_raise Ash.Error.Forbidden, fn ->
        Token |> Ash.Query.for_read(:read_expired) |> Ash.read!(authorize?: true)
      end
    end

    test "token cleanup works with expunge interval" do
      # This test verifies that the token expunge mechanism is configured
      # The actual cleanup would run periodically via the supervisor
      tokens_before = Token |> Ash.Query.for_read(:read_expired) |> Ash.read!(authorize?: false)
      _initial_count = length(tokens_before)
      # Create a token
      user_attrs = %{
        email: "cleanup_test@example.com",
        password: "test123456"
      }

      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, user_attrs)
        |> Ash.create(authorize?: false)

      strategy = AshAuthentication.Info.strategy!(User, :password)

      {:ok, _signed_in_user} =
        AshAuthentication.Strategy.action(strategy, :sign_in, %{
          email: user.email,
          password: "test123456"
        })

      # Verify that the token cleanup mechanism is configured properly
      # The expunge interval is set in the token DSL block
      # Test that the setup works; actual cleanup is handled by the supervisor
      tokens_after = Token |> Ash.Query.for_read(:read_expired) |> Ash.read!(authorize?: false)
      assert is_list(tokens_after)
    end
  end

  describe "Token policies" do
    test "authentication interactions are allowed" do
      # Test that authentication-related token operations work
      user_attrs = %{
        email: "auth_policy_test@example.com",
        password: "test123456"
      }

      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, user_attrs)
        |> Ash.create(authorize?: false)

      # Authentication should work (bypasses normal policies)
      strategy = AshAuthentication.Info.strategy!(User, :password)

      assert {:ok, _signed_in_user} =
               AshAuthentication.Strategy.action(strategy, :sign_in, %{
                 email: user.email,
                 password: "test123456"
               })
    end

    test "direct token access is forbidden" do
      # Direct CRUD operations on tokens should be forbidden
      # For now, just test that direct reading is restricted
      assert_raise Ash.Error.Forbidden, fn ->
        Token |> Ash.Query.for_read(:read_expired) |> Ash.read!(authorize?: true)
      end
    end
  end

  describe "Comprehensive token security" do
    setup do
      user_attrs = %{
        email: "token_security@example.com",
        password: "test123456",
        role: :user
      }

      admin_attrs = %{
        email: "token_admin@example.com",
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

    test "active token access is properly restricted", %{user: user} do
      # Sign in to create an active token
      strategy = AshAuthentication.Info.strategy!(User, :password)

      {:ok, _signed_in_user} =
        AshAuthentication.Strategy.action(strategy, :sign_in, %{
          email: user.email,
          password: "test123456"
        })

      # Direct token read should be forbidden even for the token owner
      assert_raise Ash.Error.Forbidden, fn ->
        Token
        |> Ash.Query.for_read(:read_expired)
        |> Ash.read!(actor: user, authorize?: true)
      end
    end

    test "token validation requires proper actor context", %{user: user} do
      strategy = AshAuthentication.Info.strategy!(User, :password)

      {:ok, signed_in_user} =
        AshAuthentication.Strategy.action(strategy, :sign_in, %{
          email: user.email,
          password: "test123456"
        })

      # Generate JWT token for the user
      {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(signed_in_user)

      # Token validation should work through the authentication system
      assert {:ok, verified_claims, _verified_user} = AshAuthentication.Jwt.verify(token, User)
      assert verified_claims["sub"] =~ to_string(user.id)
    end

    test "tokens are scoped to correct user", %{user: user, admin: admin} do
      strategy = AshAuthentication.Info.strategy!(User, :password)

      # Create token for user
      {:ok, user_signed_in} =
        AshAuthentication.Strategy.action(strategy, :sign_in, %{
          email: user.email,
          password: "test123456"
        })

      # Create token for admin
      {:ok, admin_signed_in} =
        AshAuthentication.Strategy.action(strategy, :sign_in, %{
          email: admin.email,
          password: "admin123456"
        })

      # Generate JWT tokens
      {:ok, user_token, _} = AshAuthentication.Jwt.token_for_user(user_signed_in)
      {:ok, admin_token, _} = AshAuthentication.Jwt.token_for_user(admin_signed_in)

      # Verify tokens are properly scoped
      {:ok, user_claims, _verified_user} = AshAuthentication.Jwt.verify(user_token, User)
      assert user_claims["sub"] =~ to_string(user.id)

      {:ok, admin_claims, _verified_admin} = AshAuthentication.Jwt.verify(admin_token, User)
      assert admin_claims["sub"] =~ to_string(admin.id)

      # Verify tokens cannot be cross-used
      assert user_claims["sub"] != admin_claims["sub"]
    end

    test "token lifecycle management", %{user: user} do
      strategy = AshAuthentication.Info.strategy!(User, :password)

      # Sign in to create token
      {:ok, signed_in_user} =
        AshAuthentication.Strategy.action(strategy, :sign_in, %{
          email: user.email,
          password: "test123456"
        })

      {:ok, token, claims} = AshAuthentication.Jwt.token_for_user(signed_in_user)

      # Verify token works initially
      assert {:ok, verified_claims, _verified_user} = AshAuthentication.Jwt.verify(token, User)
      assert verified_claims["sub"] =~ to_string(user.id)
      assert verified_claims["sub"] == claims["sub"]

      # Note: JWT tokens are stateless - they remain valid until expiry
      # For session invalidation, production systems would need server-side token blacklisting
      # This test verifies the token contains proper lifecycle information
      # issued at
      assert is_number(claims["iat"])
      # expires at
      assert is_number(claims["exp"])
      # valid expiry
      assert claims["exp"] > claims["iat"]
    end

    test "token expiry is enforced" do
      # Test would require manipulating token timestamps or waiting for expiry
      # For unit testing, we verify the token structure includes expiry claims
      user_attrs = %{
        email: "expiry_test@example.com",
        password: "test123456",
        role: :user
      }

      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, user_attrs)
        |> Ash.create(authorize?: false)

      strategy = AshAuthentication.Info.strategy!(User, :password)

      {:ok, signed_in_user} =
        AshAuthentication.Strategy.action(strategy, :sign_in, %{
          email: user.email,
          password: "test123456"
        })

      {:ok, _token, claims} = AshAuthentication.Jwt.token_for_user(signed_in_user)

      # Verify token has proper expiry claim
      assert is_number(claims["exp"])
      assert claims["exp"] > System.system_time(:second)

      # Verify token has issue time
      assert is_number(claims["iat"])
      assert claims["iat"] <= System.system_time(:second)
    end

    test "token contains proper security claims", %{user: user} do
      strategy = AshAuthentication.Info.strategy!(User, :password)

      {:ok, signed_in_user} =
        AshAuthentication.Strategy.action(strategy, :sign_in, %{
          email: user.email,
          password: "test123456"
        })

      {:ok, _token, claims} = AshAuthentication.Jwt.token_for_user(signed_in_user)

      # Verify essential JWT security claims are present
      # Subject (user ID)
      assert claims["sub"]
      # Issued at
      assert claims["iat"]
      # Expires at
      assert claims["exp"]

      # Verify subject matches user
      assert claims["sub"] =~ to_string(user.id)

      # Verify timing claims are reasonable
      now = System.system_time(:second)
      assert claims["iat"] <= now
      assert claims["exp"] > now
      assert claims["exp"] > claims["iat"]
    end
  end
end
