# User Management System

The user system manages authentication and roles (admin, node_operator, user).

## Create Users with Different Roles

Each role has different permissions in the system.

```elixir
# ===== CREATE USERS WITH DIFFERENT ROLES =====

# Admin: Full system access
admin = (XPando.Core.User
|> Ash.Changeset.for_create(:register_with_password, %{
  email: "admin@xpando.ai",
  password: "admin12345",  # Minimum 8 characters required
  role: :admin
})
|> Ash.create!(authorize?: false))

# Expected output: %XPando.Core.User{email: "admin@xpando.ai", role: :admin, ...}
IO.puts("✅ Admin created with ID: #{admin.id}")

# Node Operator: Can manage nodes
operator = (XPando.Core.User
|> Ash.Changeset.for_create(:register_with_password, %{
  email: "operator@xpando.ai", 
  password: "operator123",  # Minimum 8 characters required
  role: :node_operator
})
|> Ash.create!(authorize?: false))

IO.puts("✅ Operator created with ID: #{operator.id}")

# Regular User: Basic access
user = (XPando.Core.User
|> Ash.Changeset.for_create(:register_with_password, %{
  email: "user@xpando.ai",
  password: "user12345",  # Minimum 8 characters required
  role: :user
})
|> Ash.create!(authorize?: false))

IO.puts("✅ User created with ID: #{user.id}")
```

## Query and Verify Users

```elixir
# ===== QUERY AND VERIFY USERS =====

# List all users - should show 3 users
users = (XPando.Core.User |> Ash.read!(authorize?: false))
IO.puts("Total users created: #{length(users)}")

# Find specific user by email
import Ash.Query

admin_user = (XPando.Core.User 
|> filter(email == "admin@xpando.ai")
|> Ash.read_one!(authorize?: false))
IO.puts("Found admin: #{admin_user.email}")

# Count users by role - useful for analytics
admin_count = (XPando.Core.User 
|> filter(role == :admin) 
|> Ash.count!(authorize?: false))
IO.puts("Number of admins: #{admin_count}")
```

## User Roles

- `:admin` - Full system access, can manage all resources
- `:node_operator` - Can manage nodes and participate in P2P network
- `:user` - Basic access to system features

## Authentication System

The Token resource manages authentication tokens automatically when users:
- Register with `register_with_password`
- Sign in via AshAuthentication actions

## Expected Outputs

- **User creation**: Returns struct with ID, email, role
- **User queries**: Returns lists of users with filtering capabilities
- **Role verification**: Shows proper role assignments and permissions

## Next: [Node Management](04_node_management.md)