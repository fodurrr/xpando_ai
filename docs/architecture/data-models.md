# Data Models

## Node

**Purpose:** Represents an AI node participating in the P2P network

**Key Attributes:**
- id: UUID - Unique node identifier
- name: String - Human-readable node name
- status: Enum - Current node state (online/offline/syncing)
- specializations: Array - Domain expertise areas
- reputation_score: Float - Network trust score
- last_heartbeat: DateTime - Last activity timestamp
- wallet_address: String - Solana wallet for XPD rewards

**TypeScript Interface:**
```typescript
interface Node {
  id: string;
  name: string;
  status: 'online' | 'offline' | 'syncing';
  specializations: string[];
  reputationScore: number;
  lastHeartbeat: Date;
  walletAddress?: string;
}
```

**Relationships:**
- Has many Contributions
- Has many Knowledge entries
- Belongs to Network cluster

## Knowledge

**Purpose:** Represents learned intelligence that can be shared across the network

**Key Attributes:**
- id: UUID - Unique knowledge identifier
- content: JSONB - Structured knowledge representation
- confidence_score: Float - Quality/reliability metric
- domain: String - Knowledge domain/category
- version: Integer - Knowledge version number
- merkle_root: String - Content verification hash
- created_by: UUID - Origin node reference

**TypeScript Interface:**
```typescript
interface Knowledge {
  id: string;
  content: Record<string, any>;
  confidenceScore: number;
  domain: string;
  version: number;
  merkleRoot: string;
  createdBy: string;
  metadata: {
    source: string;
    timestamp: Date;
    validations: number;
  };
}
```

**Relationships:**
- Belongs to Node (creator)
- Has many Contributions
- Has many Validations

## Contribution

**Purpose:** Tracks knowledge contributions for XPD token rewards

**Key Attributes:**
- id: UUID - Unique contribution identifier
- node_id: UUID - Contributing node
- knowledge_id: UUID - Associated knowledge
- quality_score: Float - Contribution quality metric
- xpd_reward: Decimal - Token reward amount
- validation_count: Integer - Peer validations received
- timestamp: DateTime - Contribution time

**TypeScript Interface:**
```typescript
interface Contribution {
  id: string;
  nodeId: string;
  knowledgeId: string;
  qualityScore: number;
  xpdReward: string; // Decimal as string
  validationCount: number;
  timestamp: Date;
  status: 'pending' | 'validated' | 'rewarded';
}
```

**Relationships:**
- Belongs to Node
- Belongs to Knowledge
- Has one Token Transaction

## MotherCore

**Purpose:** Distributed consensus state for collective intelligence

**Key Attributes:**
- id: UUID - Core instance identifier
- genesis_node: Boolean - Whether this is a genesis node
- consensus_state: JSONB - Current consensus data
- network_version: String - Protocol version
- total_knowledge: Integer - Knowledge entries managed
- last_sync: DateTime - Last network synchronization

**TypeScript Interface:**
```typescript
interface MotherCore {
  id: string;
  genesisNode: boolean;
  consensusState: Record<string, any>;
  networkVersion: string;
  totalKnowledge: number;
  lastSync: Date;
  peers: string[]; // Connected node IDs
}
```

**Relationships:**
- Manages many Nodes
- Aggregates all Knowledge
- Coordinates Network consensus