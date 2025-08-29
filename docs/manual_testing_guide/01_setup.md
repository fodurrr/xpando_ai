# Getting Started with XPando AI Testing

> **Purpose**: Initial setup and prerequisites for testing the XPando AI P2P distributed network
> 
> **What is XPando AI?** A decentralized P2P network where AI nodes share knowledge, validate contributions, and earn reputation/tokens.

---

## Prerequisites

- Elixir and Phoenix installed
- PostgreSQL running
- Basic understanding of Elixir syntax

## Initial Setup

```bash
# Step 1: Database setup (run once)
mix ash.setup

# Step 2: Start Phoenix server (Terminal 1)
# This starts all 3 umbrella apps: xpando_core, xpando_web, xpando_node
mix phx.server
```

```bash
# Step 3: Open IEx console (Terminal 2)
# This is where you'll run all the test commands
iex -S mix
```

> **💡 IEx Tip**: In IEx, pipelines after assignments need parentheses: `var = (Module |> function())`

## Next Steps

After completing the setup:
1. Run the [Quick Start Test](02_quick_start.md) to verify everything works
2. Or test individual features:
   - [User Management](03_user_management.md)
   - [Node Registration](04_node_management.md)
   - [Knowledge Distribution](05_knowledge_distribution.md)