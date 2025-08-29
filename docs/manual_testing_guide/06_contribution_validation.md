# Contribution & Validation System

Nodes validate and enhance each other's knowledge contributions.

## Create Contributions

Contributions represent peer review and validation.

```elixir
# ===== CONTRIBUTION CREATION (CURRENTLY HAS ISSUES) =====

# ⚠️ NOTE: The Contribution resource currently has action configuration issues:
# - :create action doesn't accept node_id, knowledge_id, contribution_type parameters
# - :record_contribution doesn't properly map arguments to attributes
# - Actions need proper change/3 functions or public attributes

# This is the intended usage once the resource is fixed:
# contribution1 = (XPando.Core.Contribution
# |> Ash.Changeset.for_create(:record_contribution, %{
#   node_id: node2.id,  # Validator node
#   knowledge_id: knowledge1.id,  # Knowledge being validated
#   contribution_type: :validation,
#   contribution_data: %{
#     "validation_score" => 9.2,
#     "feedback" => "Excellent technical accuracy"
#   }
# })
# |> Ash.create!(authorize?: false))

IO.puts("⚠️  Contribution creation currently disabled due to action configuration issues")
IO.puts("   See resource definition for required fixes")

# Test what we can - contribution queries and relationships
import Ash.Query

# Check existing contributions
existing_contributions = XPando.Core.Contribution |> Ash.read!(authorize?: false)
IO.puts("Found #{length(existing_contributions)} existing contributions")

# Test relationship queries
knowledge_with_contributions = (XPando.Core.Knowledge 
|> load([:contributions])
|> Ash.read!(authorize?: false))

IO.puts("Knowledge items with contribution relationships:")
for knowledge <- knowledge_with_contributions do
  contribution_count = length(knowledge.contributions)
  IO.puts("  - #{knowledge.title}: #{contribution_count} contributions")
end
```

## Contribution Types

- `:validation` - Peer review and scoring of knowledge
- `:enhancement` - Adding improvements or corrections
- `:challenge` - Challenging the accuracy of content

## Contribution Actions

- `:create` - Basic contribution creation
- `:record_contribution` - Create with additional tracking data

## Expected Outputs

- **Contribution creation**: Returns struct with ID, node_id, knowledge_id
- **Validation scores**: Decimal values between 0-10
- **Contribution data**: Additional metadata stored as map

## Next: [P2P Network Testing](07_p2p_network.md)