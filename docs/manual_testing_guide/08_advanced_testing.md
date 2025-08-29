# Advanced Testing Scenarios

Test complex system behaviors including reputation evolution and load testing.

## Reputation System Evolution

Test how reputation changes with validations.

```elixir
# ===== SIMULATE REPUTATION CHANGES =====

# Get current reputation
import Ash.Query
current_node = (XPando.Core.Node |> limit(1) |> Ash.read_one!(authorize?: false))
IO.puts("Starting reputation: #{current_node.reputation_score}")

# Simulate 5 validation rounds
for i <- 1..5 do
  success = rem(i, 2) == 0  # Alternate success/failure
  new_rep = if success do
    Decimal.add(current_node.reputation_score, Decimal.new("2.0"))
  else
    Decimal.sub(current_node.reputation_score, Decimal.new("1.0"))
  end
  
  updated = (current_node
  |> Ash.Changeset.for_update(:update_reputation, %{
    new_reputation: new_rep,
    validation_result: success
  })
  |> Ash.update!())
  
  IO.puts("Round #{i}: Success=#{success}, New reputation=#{updated.reputation_score}")
end

# Check final metrics
final_node = (XPando.Core.Node |> Ash.get!(node1.id))
IO.puts("Final reputation: #{final_node.reputation_score}")
IO.puts("Total validations: #{final_node.total_validations}")
IO.puts("Successful validations: #{final_node.successful_validations}")
```

## Load Testing

Create bulk data to test system performance.

```elixir
# ===== CREATE BULK TEST DATA =====

IO.puts("Creating 10 knowledge items...")

# Get a node for submitter_id
node = (XPando.Core.Node |> limit(1) |> Ash.read_one!(authorize?: false))

knowledge_items = for i <- 1..10 do
  (XPando.Core.Knowledge
  |> Ash.Changeset.for_create(:submit_for_validation, %{
    submitter_node_id: node.id,
    title: "Load Test Knowledge Item #{i}",
    content: "Generated content for testing purposes #{i}. This content meets the minimum length requirement for knowledge submission.",
    category: "load_testing",
    knowledge_type: [:insight, :fact, :procedure, :pattern, :hypothesis, :observation] |> Enum.random()
  })
  |> Ash.create!(authorize?: false))
end

IO.puts("✅ Created #{length(knowledge_items)} knowledge items")

# Verify creation
total_knowledge = (XPando.Core.Knowledge |> Ash.count!(authorize?: false))
IO.puts("Total knowledge in database: #{total_knowledge}")
```

## Performance Monitoring

Measure system performance metrics.

```elixir
# ===== MEASURE QUERY PERFORMANCE =====

# Time database operations (returns {microseconds, result})
{time1, nodes} = :timer.tc(fn -> XPando.Core.Node |> Ash.read!(authorize?: false) end)
IO.puts("Node query time: #{time1/1000}ms (#{length(nodes)} nodes)")

{time2, knowledge} = :timer.tc(fn -> XPando.Core.Knowledge |> Ash.read!(authorize?: false) end)
IO.puts("Knowledge query time: #{time2/1000}ms (#{length(knowledge)} items)")

# Check memory usage
memory = :erlang.memory()
IO.puts("Total memory: #{Float.round(memory[:total] / 1_048_576, 2)} MB")
IO.puts("Processes: #{Float.round(memory[:processes] / 1_048_576, 2)} MB")
```

## Expected Outputs

- **Reputation changes**: Shows incremental reputation updates with validation counts
- **Load test**: Creates specified number of test items with random attributes
- **Performance metrics**: Query times in milliseconds and memory usage in MB

## Next: [Troubleshooting & Utilities](09_troubleshooting.md)