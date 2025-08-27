# Data Models

Based on the PRD's functional requirements and domain analysis, I've identified the core business entities that form xPando's data foundation. These models will be implemented as **Ash Resources** with shared structs for consistent data handling across the application.

## Node

**Purpose:** Represents an individual AI node in the distributed P2P network, tracking identity, capabilities, specialization, and operational status.

**Key Attributes:**
- id: UUID - Unique cryptographic node identifier
- public_key: String - Ed25519 public key for node authentication  
- node_type: Enum(genesis, expert, participant) - Node role in network hierarchy
- specialization_domains: Array(String) - Specialized expertise areas
- reputation_score: Decimal - Historical contribution quality score
- status: Enum(online, offline, connecting, maintenance) - Current operational state
- last_seen_at: DateTime - Last network activity timestamp
- connection_count: Integer - Current P2P connections maintained

### Ash Resource Definition
```elixir
defmodule XPando.Core.Node do
  use Ash.Resource, data_layer: AshPostgres.DataLayer
  
  postgres do
    table "nodes"
    repo XPando.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :public_key, :string, allow_nil?: false
    attribute :node_type, :atom, constraints: [one_of: [:genesis, :expert, :participant]]
    attribute :specialization_domains, {:array, :string}, default: []
    attribute :reputation_score, :decimal, default: Decimal.new("0.0")
    attribute :status, :atom, constraints: [one_of: [:online, :offline, :connecting, :maintenance]]
    attribute :last_seen_at, :utc_datetime
    attribute :connection_count, :integer, default: 0
    attribute :metadata, :map, default: %{}
    
    timestamps()
  end

  relationships do
    has_many :contributions, XPando.Core.Contribution
    has_many :knowledge_contributions, XPando.Core.Knowledge do
      source_attribute :id
      destination_attribute :id
      through XPando.Core.Contribution
    end
  end
end
```

### Relationships
- Has many Knowledge contributions (one-to-many through Contributions)
- Has many Contributions directly (one-to-many)
- Can connect to other Nodes via network topology tracking

## Knowledge

**Purpose:** Stores collective intelligence insights with confidence scoring, provenance tracking, and version management for distributed AI collaboration.

**Key Attributes:**
- id: UUID - Unique knowledge identifier
- content: Text - Main knowledge content/insight  
- content_hash: String - SHA-256 for deduplication and integrity
- confidence_score: Decimal - Aggregate quality/reliability score
- knowledge_type: Enum(insight, fact, procedure, pattern) - Classification of knowledge
- domain_tags: Array(String) - Subject matter categorization
- source_count: Integer - Number of contributing nodes
- validation_status: Enum(pending, validated, disputed, archived) - Consensus state

### Ash Resource Definition
```elixir
defmodule XPando.Core.Knowledge do
  use Ash.Resource, data_layer: AshPostgres.DataLayer
  
  postgres do
    table "knowledge"
    repo XPando.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :content, :string, allow_nil?: false
    attribute :content_hash, :string, allow_nil?: false
    attribute :confidence_score, :decimal, default: Decimal.new("0.0")
    attribute :knowledge_type, :atom, constraints: [one_of: [:insight, :fact, :procedure, :pattern]]
    attribute :domain_tags, {:array, :string}, default: []
    attribute :source_count, :integer, default: 0
    attribute :validation_status, :atom, constraints: [one_of: [:pending, :validated, :disputed, :archived]]
    attribute :metadata, :map, default: %{}
    
    timestamps()
  end

  relationships do
    has_many :contributions, XPando.Core.Contribution
    has_many :contributing_nodes, XPando.Core.Node do
      source_attribute :id
      destination_attribute :id
      through XPando.Core.Contribution
    end
  end

  calculations do
    calculate :average_quality, :decimal, expr(
      fragment("SELECT AVG(quality_score) FROM contributions WHERE knowledge_id = ?", id)
    )
  end
end
```

### Relationships
- Has many Contributions (one-to-many)
- Belongs to multiple Nodes through Contributions (many-to-many)
- Can reference other Knowledge for synthesis tracking

## Contribution

**Purpose:** Tracks individual node contributions to the collective knowledge base with quality assessment and reward calculations for the XPD token economy.

**Key Attributes:**
- id: UUID - Unique contribution identifier
- node_id: UUID - Contributing node reference
- knowledge_id: UUID - Knowledge being contributed to
- contribution_type: Enum(creation, validation, synthesis, correction) - Type of contribution
- quality_score: Decimal - Assessed value of this specific contribution
- tokens_earned: Integer - XPD tokens awarded for contribution
- peer_validations: Integer - Number of peer reviews received
- contribution_weight: Decimal - Influence on final knowledge confidence

### Ash Resource Definition
```elixir
defmodule XPando.Core.Contribution do
  use Ash.Resource, data_layer: AshPostgres.DataLayer
  
  postgres do
    table "contributions"
    repo XPando.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :contribution_type, :atom, constraints: [one_of: [:creation, :validation, :synthesis, :correction]]
    attribute :quality_score, :decimal, default: Decimal.new("0.0")
    attribute :tokens_earned, :integer, default: 0
    attribute :peer_validations, :integer, default: 0
    attribute :contribution_weight, :decimal, default: Decimal.new("1.0")
    attribute :metadata, :map, default: %{}
    
    timestamps()
  end

  relationships do
    belongs_to :node, XPando.Core.Node
    belongs_to :knowledge, XPando.Core.Knowledge
  end

  actions do
    defaults [:create, :read, :update, :destroy]
    
    create :award_tokens do
      argument :token_amount, :integer
      change set_attribute(:tokens_earned, arg(:token_amount))
    end
  end
end
```

### Relationships
- Belongs to Node (many-to-one)
- Belongs to Knowledge (many-to-one)
- Acts as join table between Nodes and Knowledge
