# Coding Standards

This document defines the comprehensive coding standards for the xPando project, covering Elixir language conventions, Ash Framework best practices, and project-specific guidelines.

## Table of Contents

- [General Elixir Standards](#general-elixir-standards)
- [Ash Framework Standards](#ash-framework-standards)
- [Project Structure](#project-structure)
- [Documentation Standards](#documentation-standards)
- [Testing Standards](#testing-standards)
- [Error Handling](#error-handling)
- [Performance Guidelines](#performance-guidelines)
- [Security Standards](#security-standards)
- [Code Review Guidelines](#code-review-guidelines)

## General Elixir Standards

### Naming Conventions

**Modules:**
```elixir
# ✅ Good - PascalCase
defmodule XPando.MotherCore.KnowledgeValidator do
  # module content
end

# ❌ Bad
defmodule xpando_mother_core_knowledge_validator do
end
```

**Functions and Variables:**
```elixir
# ✅ Good - snake_case
def validate_knowledge_integrity(knowledge_item) do
  consensus_score = calculate_consensus_score(knowledge_item)
  # implementation
end

# ❌ Bad
def validateKnowledgeIntegrity(knowledgeItem) do
end
```

**Atoms:**
```elixir
# ✅ Good - snake_case
:knowledge_validated
:consensus_reached
:validation_pending

# ❌ Bad
:knowledgeValidated
:ConsensusReached
```

### Code Formatting

**Use mix format consistently:**
```bash
# Always format before committing
mix format
```

**Line Length:**
- Maximum 100 characters per line
- Break long function calls and pipelines logically

**Pipe Operator Usage:**
```elixir
# ✅ Good - Clear data flow
knowledge
|> validate_structure()
|> check_consensus()
|> store_if_valid()
|> notify_network()

# ❌ Bad - Nested function calls
notify_network(store_if_valid(check_consensus(validate_structure(knowledge))))
```

**Pattern Matching:**
```elixir
# ✅ Good - Clear pattern matching
case validate_knowledge(knowledge) do
  {:ok, validated_knowledge} -> process_knowledge(validated_knowledge)
  {:error, :invalid_structure} -> handle_structure_error()
  {:error, :consensus_failed} -> handle_consensus_error()
end

# ❌ Bad - Catch-all without specific handling
case validate_knowledge(knowledge) do
  {:ok, result} -> process_knowledge(result)
  _ -> handle_error()
end
```

### Function Organization

**Function Ordering:**
1. Public functions (with `@doc`)
2. Private functions (with `@doc false` if documented)
3. Helper functions

```elixir
defmodule XPando.MotherCore.Validator do
  @doc """
  Validates knowledge item against consensus requirements.
  Returns {:ok, validated_knowledge} or {:error, reason}.
  """
  def validate_knowledge(knowledge_item) do
    # implementation
  end

  @doc """
  Calculates consensus score based on validator responses.
  """
  def calculate_consensus_score(validations) do
    # implementation
  end

  # Private functions
  defp normalize_validation_scores(scores) do
    # implementation
  end

  defp apply_weight_factors(scores, validators) do
    # implementation
  end
end
```

## Ash Framework Standards

### Resource Definition

**Use clear, descriptive resource names:**
```elixir
# ✅ Good
defmodule XPando.Knowledge.KnowledgeItem do
  use Ash.Resource,
    domain: XPando.Knowledge,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAi]

  postgres do
    table "knowledge_items"
    repo XPando.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :content, :string do
      allow_nil? false
      description "The actual knowledge content"
    end

    attribute :confidence_score, :decimal do
      constraints precision: 5, scale: 3
      description "Consensus confidence score (0.000-1.000)"
    end

    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    create :submit_for_validation do
      description "Submit knowledge item for network validation"
      
      argument :submitter_node_id, :uuid do
        allow_nil? false
      end

      change set_attribute(:status, :pending_validation)
      change relate_actor(:submitter)
    end
  end

  relationships do
    belongs_to :submitter, XPando.Network.Node
    has_many :validations, XPando.Knowledge.Validation
  end
end
```

### Domain Organization

**Group related resources in domains:**
```elixir
# ✅ Good - Clear domain separation
defmodule XPando.Knowledge do
  use Ash.Domain

  resources do
    resource XPando.Knowledge.KnowledgeItem
    resource XPando.Knowledge.Validation
    resource XPando.Knowledge.ConsensusResult
  end
end

defmodule XPando.Network do
  use Ash.Domain

  resources do
    resource XPando.Network.Node
    resource XPando.Network.Connection
    resource XPando.Network.Topology
  end
end
```

### Action Definitions

**Clear action naming and documentation:**
```elixir
actions do
  # ✅ Good - Descriptive names with clear intent
  read :list_pending_validations do
    description "Get all knowledge items awaiting validation"
    
    filter expr(status == :pending_validation)
    pagination offset?: true, keyset?: true, required?: false
  end

  update :approve_knowledge do
    description "Mark knowledge as validated and approved"
    
    argument :validator_id, :uuid, allow_nil?: false
    argument :confidence_score, :decimal, allow_nil?: false
    
    change set_attribute(:status, :validated)
    change set_attribute(:validated_at, &DateTime.utc_now/0)
    change relate_actor(:validator)
  end
end
```

### Calculations and Preparations

```elixir
calculations do
  calculate :weighted_confidence, :decimal, expr(
    confidence_score * validation_weight
  ) do
    description "Confidence score adjusted by validator weight"
  end

  calculate :days_since_validation, :integer, DaysAgo do
    description "Number of days since knowledge was validated"
    argument :from_date, :utc_datetime, allow_nil?: true
  end
end

preparations do
  prepare build(load: [:submitter, :validations])
end
```

### ash_ai Integration

```elixir
# ✅ Good - Proper ash_ai setup for vectorization
defmodule XPando.Knowledge.KnowledgeItem do
  use Ash.Resource,
    domain: XPando.Knowledge,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAi]

  vectorize do
    full_text do
      text(fn record ->
        """
        Content: #{record.content}
        Category: #{record.category}
        Keywords: #{Enum.join(record.keywords || [], ", ")}
        """
      end)

      used_attributes [:content, :category, :keywords]
    end

    strategy :ash_oban
    embedding_model XPando.AI.EmbeddingModel
  end

  # Action for semantic search
  read :semantic_search do
    description "Search knowledge items by semantic similarity"
    
    argument :query, :string, allow_nil?: false
    
    prepare before_action(fn query, _context ->
      search_query = query.arguments.query
      
      case XPando.AI.EmbeddingModel.generate([search_query], []) do
        {:ok, [search_vector]} ->
          Ash.Query.filter(
            query,
            vector_cosine_distance(full_text_vector, ^search_vector) < 0.5
          )
          |> Ash.Query.sort(asc: vector_cosine_distance(full_text_vector, ^search_vector))
          |> Ash.Query.limit(20)

        {:error, error} ->
          {:error, error}
      end
    end)
  end
end
```

## Project Structure

### Directory Organization

```
lib/
├── xpando/
│   ├── application.ex              # Main application
│   ├── repo.ex                     # Database repository
│   └── domains/
│       ├── knowledge/              # Knowledge domain
│       │   ├── knowledge.ex        # Domain definition
│       │   ├── resources/
│       │   │   ├── knowledge_item.ex
│       │   │   └── validation.ex
│       │   └── calculations/
│       │       └── consensus_score.ex
│       ├── network/                # Network domain
│       │   ├── network.ex
│       │   └── resources/
│       │       ├── node.ex
│       │       └── connection.ex
│       └── blockchain/             # Blockchain domain
│           ├── blockchain.ex
│           └── resources/
│               └── xpd_transaction.ex
└── xpando_web/
    ├── components/
    ├── controllers/
    ├── live/
    └── router.ex
```

### File Naming

```elixir
# ✅ Good - Clear, descriptive names
lib/xpando/knowledge/resources/knowledge_item.ex
lib/xpando/network/calculations/trust_score.ex
lib/xpando_web/live/knowledge/knowledge_live.ex

# ❌ Bad - Abbreviated or unclear names
lib/xpando/k/res/ki.ex
lib/xpando/net/calc/ts.ex
```

## Documentation Standards

### Module Documentation

```elixir
defmodule XPando.MotherCore.ConsensusEngine do
  @moduledoc """
  Implements Byzantine fault-tolerant consensus mechanism for knowledge validation.

  The ConsensusEngine coordinates validation requests across network nodes,
  aggregates responses using weighted voting, and determines final consensus
  results based on configurable thresholds.

  ## Examples

      iex> ConsensusEngine.initiate_validation(knowledge_item)
      {:ok, %ValidationSession{}}

      iex> ConsensusEngine.calculate_consensus(validations)
      {:ok, %ConsensusResult{confidence: 0.847}}

  ## Configuration

  The consensus engine can be configured in `config/config.exs`:

      config :xpando, XPando.MotherCore.ConsensusEngine,
        min_validators: 5,
        consensus_threshold: 0.75,
        timeout_ms: 30_000
  """

  @doc """
  Initiates validation process for a knowledge item.

  Selects appropriate validators based on expertise matching and
  distributes validation requests across the network.

  ## Parameters

    - `knowledge_item` - The knowledge item to validate
    - `opts` - Optional configuration (timeout, min_validators)

  ## Returns

    - `{:ok, validation_session}` - Validation initiated successfully
    - `{:error, :insufficient_validators}` - Not enough validators available
    - `{:error, :network_unavailable}` - Network connectivity issues

  ## Examples

      iex> knowledge = %KnowledgeItem{content: "E=mc²", category: :physics}
      iex> ConsensusEngine.initiate_validation(knowledge)
      {:ok, %ValidationSession{id: "abc123", status: :pending}}
  """
  def initiate_validation(knowledge_item, opts \\ []) do
    # implementation
  end
end
```

### Function Documentation

```elixir
@doc """
Short one-line description of the function.

Longer description with more details about the function's behavior,
edge cases, and important implementation notes.

## Parameters

  - `param1` - Description of first parameter
  - `param2` - Description of second parameter with type info

## Returns

  - Description of return value and its structure

## Examples

    iex> function_name(param1, param2)
    expected_result

## See also

  - `related_function/2`
  - `OtherModule.function/1`
"""
def function_name(param1, param2) do
  # implementation
end
```

### Inline Comments

```elixir
def complex_calculation(data) do
  # Normalize data to prevent division by zero
  normalized_data = Enum.map(data, &max(&1, 0.001))
  
  # Apply weighted scoring algorithm based on validator reputation
  weighted_scores = 
    normalized_data
    |> Enum.zip(validator_weights)
    |> Enum.map(fn {score, weight} -> score * weight end)
  
  # Calculate final result using Byzantine fault tolerance threshold
  total_weight = Enum.sum(validator_weights)
  weighted_average = Enum.sum(weighted_scores) / total_weight
  
  # Return result with confidence interval
  {:ok, weighted_average, calculate_confidence_interval(weighted_scores)}
end
```

## Testing Standards

### Test Organization

```elixir
defmodule XPando.Knowledge.KnowledgeItemTest do
  use XPando.DataCase
  
  alias XPando.Knowledge.KnowledgeItem

  describe "create/1" do
    test "creates knowledge item with valid attributes" do
      attrs = %{
        content: "Test knowledge content",
        category: :general,
        submitter_id: insert(:node).id
      }

      assert {:ok, knowledge_item} = KnowledgeItem.create(attrs)
      assert knowledge_item.content == attrs.content
      assert knowledge_item.status == :pending_validation
    end

    test "returns error with invalid content" do
      attrs = %{content: "", category: :general}
      
      assert {:error, changeset} = KnowledgeItem.create(attrs)
      assert "can't be blank" in errors_on(changeset).content
    end
  end

  describe "semantic_search/1" do
    setup do
      # Create test knowledge items with known vectors
      knowledge_items = [
        insert(:knowledge_item, content: "Einstein's theory of relativity"),
        insert(:knowledge_item, content: "Quantum mechanics principles"),
        insert(:knowledge_item, content: "Cooking pasta recipes")
      ]
      
      %{knowledge_items: knowledge_items}
    end

    test "returns semantically similar items", %{knowledge_items: items} do
      query = "physics theories"
      
      result = KnowledgeItem.semantic_search!(query: query)
      
      # Should return physics-related items first
      assert length(result) >= 2
      assert Enum.any?(result, &String.contains?(&1.content, "Einstein"))
    end
  end
end
```

### Factory Definitions

```elixir
# test/support/factory.ex
defmodule XPando.Factory do
  use ExMachina.Ecto, repo: XPando.Repo

  def node_factory do
    %XPando.Network.Node{
      name: sequence("node"),
      endpoint: sequence("https://node-") <> ".example.com",
      public_key: generate_public_key(),
      reputation_score: Decimal.new("0.75"),
      status: :active
    }
  end

  def knowledge_item_factory do
    %XPando.Knowledge.KnowledgeItem{
      content: "Sample knowledge content",
      category: :general,
      confidence_score: Decimal.new("0.0"),
      status: :pending_validation,
      submitter: build(:node)
    }
  end

  def validation_factory do
    %XPando.Knowledge.Validation{
      confidence_score: Decimal.new("0.8"),
      reasoning: "Valid knowledge based on scientific consensus",
      validator: build(:node),
      knowledge_item: build(:knowledge_item)
    }
  end

  defp generate_public_key do
    :crypto.strong_rand_bytes(32) |> Base.encode64()
  end
end
```

## Error Handling

### Consistent Error Patterns

```elixir
# ✅ Good - Consistent error tuples
def validate_knowledge(knowledge_item) do
  with {:ok, structure} <- validate_structure(knowledge_item),
       {:ok, content} <- validate_content(structure),
       {:ok, consensus} <- check_consensus(content) do
    {:ok, consensus}
  else
    {:error, :invalid_structure} = error -> error
    {:error, :content_validation_failed} = error -> error
    {:error, :consensus_threshold_not_met} = error -> error
    {:error, reason} -> {:error, {:validation_failed, reason}}
  end
end

# ❌ Bad - Inconsistent error handling
def validate_knowledge(knowledge_item) do
  case validate_structure(knowledge_item) do
    {:ok, structure} ->
      case validate_content(structure) do
        {:ok, content} -> check_consensus(content)
        error -> error
      end
    _ -> :error
  end
end
```

### Error Documentation

```elixir
@doc """
Validates knowledge item structure and content.

## Error Codes

  - `{:error, :invalid_structure}` - Knowledge item missing required fields
  - `{:error, :content_too_short}` - Content below minimum length requirement
  - `{:error, :content_too_long}` - Content exceeds maximum length
  - `{:error, :invalid_category}` - Category not in allowed list
  - `{:error, {:validation_timeout, timeout_ms}}` - Validation took too long

## Examples

    iex> validate_knowledge(%KnowledgeItem{content: nil})
    {:error, :invalid_structure}
"""
def validate_knowledge(knowledge_item) do
  # implementation
end
```

## Performance Guidelines

### Database Queries

```elixir
# ✅ Good - Use specific selects and includes
def list_recent_knowledge(limit \\ 50) do
  KnowledgeItem
  |> Ash.Query.select([:id, :content, :confidence_score, :inserted_at])
  |> Ash.Query.load([:submitter])
  |> Ash.Query.sort(desc: :inserted_at)
  |> Ash.Query.limit(limit)
  |> Ash.read!()
end

# ❌ Bad - Loading all fields and relationships
def list_recent_knowledge(limit \\ 50) do
  KnowledgeItem
  |> Ash.Query.load([:submitter, :validations, :consensus_results])
  |> Ash.Query.sort(desc: :inserted_at)
  |> Ash.read!()
  |> Enum.take(limit)
end
```

### Memory Management

```elixir
# ✅ Good - Stream large datasets
def process_all_knowledge do
  KnowledgeItem
  |> Ash.stream!()
  |> Stream.map(&process_knowledge_item/1)
  |> Stream.run()
end

# ❌ Bad - Loading all records into memory
def process_all_knowledge do
  KnowledgeItem
  |> Ash.read!()
  |> Enum.each(&process_knowledge_item/1)
end
```

## Security Standards

### Input Validation

```elixir
# ✅ Good - Explicit validation with clear constraints
attributes do
  attribute :content, :string do
    constraints max_length: 10_000, min_length: 10
    description "Knowledge content (10-10000 characters)"
  end

  attribute :category, :atom do
    constraints one_of: [:science, :technology, :mathematics, :general]
    default :general
  end

  attribute :confidence_threshold, :decimal do
    constraints min: 0, max: 1, precision: 3, scale: 3
    default 0.75
  end
end
```

### Authorization

```elixir
# ✅ Good - Explicit policies with clear rules
policies do
  bypass actor_attribute_equals(:role, :system_admin)

  policy action(:read) do
    description "Anyone can read validated knowledge"
    authorize_if expr(status == :validated)
  end

  policy action(:create) do
    description "Only active nodes can submit knowledge"
    authorize_if actor_attribute_equals(:status, :active)
    authorize_if relates_to_actor_via(:submitter)
  end

  policy action(:update) do
    description "Only knowledge submitter can update pending items"
    authorize_if relates_to_actor_via(:submitter)
    authorize_if expr(status == :pending_validation)
  end
end
```

### Data Sanitization

```elixir
changes do
  # ✅ Good - Sanitize and validate input data
  change fn changeset, _context ->
    case Ash.Changeset.get_argument(changeset, :content) do
      nil -> changeset
      content -> 
        sanitized_content = 
          content
          |> String.trim()
          |> String.replace(~r/\s+/, " ")  # Normalize whitespace
          |> HtmlSanitizeEx.strip_tags()   # Remove HTML tags
        
        Ash.Changeset.change_attribute(changeset, :content, sanitized_content)
    end
  end
end
```

## Code Review Guidelines

### Checklist for Reviewers

**Functionality:**
- [ ] Code solves the intended problem
- [ ] Edge cases are handled appropriately
- [ ] Error conditions are properly managed
- [ ] Tests cover happy path and error scenarios

**Code Quality:**
- [ ] Functions are focused and do one thing well
- [ ] Variable and function names are descriptive
- [ ] Code follows established patterns
- [ ] No code duplication without justification

**Ash Framework:**
- [ ] Resources properly define attributes and relationships
- [ ] Actions have clear descriptions and proper arguments
- [ ] Policies are explicit and secure
- [ ] ash_ai integration follows best practices

**Documentation:**
- [ ] Public functions have proper @doc strings
- [ ] Module documentation explains purpose and usage
- [ ] Examples are provided for complex functions
- [ ] Inline comments explain complex logic

**Performance:**
- [ ] Database queries are optimized
- [ ] Large datasets use streaming
- [ ] Unnecessary computations are avoided
- [ ] Memory usage is reasonable

**Security:**
- [ ] Input validation is comprehensive
- [ ] Authorization policies are correct
- [ ] No sensitive data in logs or errors
- [ ] Proper data sanitization

### Pull Request Template

```markdown
## Description
Brief description of changes and why they were made.

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)  
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Performance impact assessed

## Ash Framework Changes
- [ ] New resources/actions documented
- [ ] Policies reviewed for security
- [ ] ash_ai integration tested
- [ ] Database migrations included (if applicable)

## Checklist
- [ ] Code follows project coding standards
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No console.log or debugging code left
- [ ] Igniter used for supported dependencies
```

This coding standards document should be regularly updated as the project evolves and new patterns emerge. All team members should review and follow these standards to ensure consistent, maintainable, and secure code across the xPando project.