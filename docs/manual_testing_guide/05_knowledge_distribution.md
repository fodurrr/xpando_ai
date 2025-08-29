# Knowledge Distribution System

Knowledge items are the core content shared across the P2P network.

## Create Knowledge Items

Knowledge represents AI-generated or curated content.

```elixir
# ===== CREATE KNOWLEDGE ITEMS =====

# Create advanced ML knowledge
# Note: Use submit_for_validation action (create action doesn't accept these parameters)
knowledge1 = (XPando.Core.Knowledge
|> Ash.Changeset.for_create(:submit_for_validation, %{
  submitter_node_id: node1.id,  # Note: different parameter name
  title: "Advanced Neural Network Architectures",
  content: "Comprehensive guide to transformer architectures and their applications in modern AI systems. Content must meet minimum length requirement.",
  category: "machine_learning",
  knowledge_type: :insight  # Required parameter for this action
})
|> Ash.create!(authorize?: false))

IO.puts("✅ Knowledge1 created: #{knowledge1.title}")
IO.puts("  Hash: #{knowledge1.content_hash}")
IO.puts("  Status: #{knowledge1.validation_status}")
IO.puts("  Submitted by: AlphaNode")

# Create distributed systems knowledge using submit_for_validation action
knowledge2 = (XPando.Core.Knowledge
|> Ash.Changeset.for_create(:submit_for_validation, %{
  submitter_node_id: node2.id,  # Note: different parameter name for this action
  title: "Distributed System Design Patterns",
  content: "Best practices for building resilient distributed systems including patterns for fault tolerance, scalability, and consistency.",
  category: "distributed_systems",
  knowledge_type: :pattern  # Must be valid enum value: :insight, :fact, :procedure, :pattern, :hypothesis, :observation
})
|> Ash.create!(authorize?: false))

IO.puts("✅ Knowledge2 created: #{knowledge2.title}")
```

## Query Knowledge Database

```elixir
# ===== QUERY KNOWLEDGE DATABASE =====

import Ash.Query

# Get all knowledge items
all_knowledge = (XPando.Core.Knowledge |> Ash.read!(authorize?: false))
IO.puts("Total knowledge items: #{length(all_knowledge)}")

# Filter by category
ml_knowledge = (XPando.Core.Knowledge 
|> filter(category == "machine_learning") 
|> Ash.read!(authorize?: false))
IO.puts("ML knowledge items: #{length(ml_knowledge)}")

# Filter by validation status
pending_knowledge = (XPando.Core.Knowledge 
|> filter(validation_status == :pending) 
|> Ash.read!(authorize?: false))
IO.puts("Pending validation items: #{length(pending_knowledge)}")

# Load knowledge with submitter details
knowledge_with_submitter = (XPando.Core.Knowledge 
|> load([:submitter])  # Loads the node that submitted it
|> Ash.read!(authorize?: false))

# Display knowledge with submitter info
IO.puts("📚 Knowledge items with submitters:")
Enum.each(knowledge_with_submitter, fn k ->
  IO.puts("  - #{k.title} (#{k.category}) - Submitted by: #{k.submitter.name}")
end)
```

## Knowledge Actions Available

- `:create` - Basic knowledge creation
- `:submit_for_validation` - Submit knowledge for peer validation workflow
- Standard query filters for category, difficulty level, etc.

## Expected Outputs

- **Knowledge creation**: Returns struct with ID, title, content_hash
- **Knowledge queries**: Returns lists of knowledge items with metadata
- **Loaded relationships**: Shows submitter node information

## Next: [Contribution & Validation System](06_contribution_validation.md)