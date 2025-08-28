# Coding Standards

## Critical Fullstack Rules

- **Ash Resource First:** Always define domain logic in Ash Resources, never bypass for direct Ecto
- **LiveView State:** Never store sensitive data in LiveView assigns, use ETS for large datasets
- **Broadway Pipelines:** All external API calls must go through Broadway for fault tolerance
- **P2P Protocol:** Use Phoenix.PubSub for all inter-node communication, no direct GenServer calls
- **Token Operations:** All Solana transactions must include retry logic and idempotency keys
- **Error Boundaries:** Every LiveView must implement handle_error callbacks
- **Migration Safety:** Never modify Ash-generated migrations directly, use Ash migrations

## Naming Conventions

| Element | Frontend | Backend | Example |
|---------|----------|---------|---------|
| LiveView modules | PascalCase + "Live" | - | `DashboardLive` |
| Components | PascalCase | - | `NodeCard` |
| Ash Resources | - | PascalCase | `XPando.Core.Node` |
| Phoenix Channels | - | snake_case + "channel" | `node_channel` |
| Database Tables | - | plural snake_case | `nodes` |
| PubSub Topics | - | colon-separated | `"network:updates"` |