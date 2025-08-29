# Troubleshooting & Utilities

Common issues, solutions, and utility functions for debugging.

## Check System Status

```elixir
# ===== CHECK SYSTEM STATUS =====

# Is Node Manager running?
manager_pid = Process.whereis(XPando.Node.Manager)
if manager_pid do
  IO.puts("✅ Node Manager running: #{inspect(manager_pid)}")
else
  IO.puts("❌ Node Manager not running!")
end

# Check supervisor tree
children = Supervisor.which_children(XpandoNode.Application)
IO.puts("Supervisor children: #{length(children)}")

# Enable debug logging
Logger.configure(level: :debug)
IO.puts("Debug logging enabled")
```

## Data Cleanup

Clean test data when needed (use with caution).

```elixir
# ===== CLEAN TEST DATA (USE WITH CAUTION!) =====

IO.puts("⚠️  Cleaning test data...")

# Clear in order due to foreign key constraints
# Note: Token cleanup is usually not needed as they're auth tokens
# {:ok, _} = XPando.Core.Token |> Ash.bulk_destroy!(:destroy, %{})
# IO.puts("Tokens cleared")

{:ok, _} = XPando.Core.Contribution |> Ash.bulk_destroy!(:destroy, %{})
IO.puts("Contributions cleared")

{:ok, _} = XPando.Core.Knowledge |> Ash.bulk_destroy!(:destroy, %{})
IO.puts("Knowledge cleared")

{:ok, _} = XPando.Core.Node |> Ash.bulk_destroy!(:destroy, %{})
IO.puts("Nodes cleared")

{:ok, _} = XPando.Core.User |> Ash.bulk_destroy!(:destroy, %{})
IO.puts("Users cleared")

IO.puts("✅ All test data cleared")
```

## Common Errors & Solutions

| Error | Solution |
|-------|----------|
| `** (Ash.Error.Invalid)` | Check required fields and data types |
| `Process XPando.Node.Manager not found` | Restart with `mix phx.server` |
| `** (DBConnection.ConnectionError)` | Ensure PostgreSQL is running |
| `unique constraint violated` | Use unique values or clean data first |

## Expected Outputs Reference

When commands work correctly, you should see:

- **User creation**: Returns struct with ID, email, role
- **Node registration**: Returns struct with ID, node_id (hash), status (:active)
- **Knowledge creation**: Returns struct with ID, title, content_hash
- **Network state**: Shows current_node, cluster_nodes list, health metrics
- **Heartbeat**: Silent success or debug log messages
- **Token awards**: Returns struct with amount, transaction_type

## Further Learning

- Review source code in `apps/xpando_core/lib/xpando/core/`
- Check tests in `apps/*/test/` for more examples
- Read Ash Framework docs: https://hexdocs.pm/ash
- Phoenix PubSub docs: https://hexdocs.pm/phoenix_pubsub

## Next: [Quick Start Test](02_quick_start.md)