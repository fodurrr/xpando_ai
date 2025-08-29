# Node Registration & Management

Nodes are AI participants in the P2P network with cryptographic identities.

## Register Nodes with Cryptographic Identity

Each node has a unique public key and signature for authentication.

```elixir
# ===== REGISTER NODES WITH CRYPTOGRAPHIC IDENTITY =====

# Generate proper Ed25519 keys for AlphaNode
{public_key, private_key} = :crypto.generate_key(:eddsa, :ed25519)
endpoint = "http://192.168.1.100:8080"
signature = :crypto.sign(:eddsa, :none, endpoint, [private_key, :ed25519])

# Register first node (AlphaNode)
node1 = (XPando.Core.Node
|> Ash.Changeset.for_create(:register, %{
  name: "AlphaNode",  # Human-readable name
  endpoint: endpoint,  # Network endpoint
  public_key: Base.encode64(public_key),  # Base64 encoded Ed25519 public key
  signature: Base.encode64(signature)  # Cryptographic proof of ownership
})
|> Ash.create!(authorize?: false))

# The system automatically:
# - Generates a unique node_id from the public key hash
# - Sets status to :active
# - Initializes reputation at 50.0
# - Sets up default metrics

IO.puts("✅ Node1 registered:")
IO.puts("  ID: #{node1.id}")
IO.puts("  Node ID: #{node1.node_id}")
IO.puts("  Status: #{node1.status}")
IO.puts("  Reputation: #{node1.reputation_score}")
```

```elixir
# Generate proper Ed25519 keys for BetaNode  
{public_key2, private_key2} = :crypto.generate_key(:eddsa, :ed25519)
endpoint2 = "http://192.168.1.101:8080"
signature2 = :crypto.sign(:eddsa, :none, endpoint2, [private_key2, :ed25519])

# Register second node (BetaNode)
node2 = (XPando.Core.Node
|> Ash.Changeset.for_create(:register, %{
  name: "BetaNode",
  endpoint: endpoint2, 
  public_key: Base.encode64(public_key2),
  signature: Base.encode64(signature2)
})
|> Ash.create!(authorize?: false))

# Note: Standard update action doesn't accept specializations, expertise_level, region
# These would need to be set via custom actions or different approach
IO.puts("⚠️  Node specializations require custom update actions - skipping for basic test")
IO.puts("✅ Node2 created successfully: #{node2.name}")
```

## Query Nodes Using Built-in Actions

```elixir
# ===== QUERY NODES USING BUILT-IN ACTIONS =====

import Ash.Query

# List all registered nodes
all_nodes = (XPando.Core.Node |> Ash.read!(authorize?: false))
IO.puts("Total nodes: #{length(all_nodes)}")

# List only active nodes (status = :active)
active_nodes = (XPando.Core.Node 
|> filter(status == :active)
|> Ash.read!(authorize?: false))
IO.puts("Active nodes: #{length(active_nodes)}")

# Show node details
for node <- active_nodes do
  IO.puts("  - #{node.name} (#{node.status}) - Reputation: #{node.reputation_score}")
end

# Note: Custom read actions like list_by_specialization require different syntax
# Find high reputation nodes (reputation >= 40.0)
high_rep_nodes = (XPando.Core.Node 
|> filter(reputation_score >= 40.0)
|> Ash.read!(authorize?: false))
IO.puts("High reputation nodes (>=40): #{length(high_rep_nodes)}")
```

## Expected Outputs

- **Node registration**: Returns struct with ID, node_id (hash), status (:active), initial reputation (50.0)
- **Node updates**: Returns updated struct with new specializations and metrics
- **Query results**: Returns lists of nodes matching specific criteria

## Next: [Knowledge Distribution System](05_knowledge_distribution.md)