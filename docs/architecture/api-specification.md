# API Specification

## GraphQL Schema

```graphql
# Root Query Type
type Query {
  # Node queries
  node(id: ID!): Node
  nodes(
    filter: NodeFilter
    sort: [NodeSort!]
    first: Int
    after: String
  ): NodeConnection!
  
  # Knowledge queries
  knowledge(id: ID!): Knowledge
  searchKnowledge(
    domain: String
    confidenceThreshold: Float
    first: Int
  ): KnowledgeConnection!
  
  # Mother Core status
  motherCoreStatus: MotherCoreStatus!
  
  # Network statistics
  networkStats: NetworkStats!
}

# Root Mutation Type
type Mutation {
  # Node operations
  registerNode(input: RegisterNodeInput!): RegisterNodePayload!
  updateNodeSpecializations(
    nodeId: ID!
    specializations: [String!]!
  ): Node!
  
  # Knowledge operations
  submitKnowledge(input: SubmitKnowledgeInput!): Knowledge!
  validateKnowledge(
    knowledgeId: ID!
    validation: ValidationInput!
  ): Knowledge!
  
  # Token operations
  claimRewards(nodeId: ID!): ClaimRewardsPayload!
}

# Root Subscription Type
type Subscription {
  # Real-time node status updates
  nodeStatusChanged(nodeId: ID): Node!
  
  # Knowledge propagation events
  knowledgeAdded(domain: String): Knowledge!
  
  # Network events
  networkEvent: NetworkEvent!
}

# Core Types
type Node {
  id: ID!
  name: String!
  status: NodeStatus!
  specializations: [String!]!
  reputationScore: Float!
  lastHeartbeat: DateTime!
  walletAddress: String
  contributions(first: Int): ContributionConnection!
  knowledge(first: Int): KnowledgeConnection!
}

type Knowledge {
  id: ID!
  content: JSON!
  confidenceScore: Float!
  domain: String!
  version: Int!
  merkleRoot: String!
  createdBy: Node!
  contributions: [Contribution!]!
  validations: [Validation!]!
}

type Contribution {
  id: ID!
  node: Node!
  knowledge: Knowledge!
  qualityScore: Float!
  xpdReward: Decimal!
  validationCount: Int!
  timestamp: DateTime!
  status: ContributionStatus!
}

# Enums
enum NodeStatus {
  ONLINE
  OFFLINE
  SYNCING
}

enum ContributionStatus {
  PENDING
  VALIDATED
  REWARDED
}

# Input Types
input RegisterNodeInput {
  name: String!
  specializations: [String!]!
  walletAddress: String
}

input SubmitKnowledgeInput {
  domain: String!
  content: JSON!
  nodeId: ID!
}

input ValidationInput {
  isValid: Boolean!
  confidenceAdjustment: Float
  feedback: String
}

# Connection Types (Relay-style pagination)
type NodeConnection {
  edges: [NodeEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type NodeEdge {
  cursor: String!
  node: Node!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}
```