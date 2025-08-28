# Epic 2: AI Provider Integration & Mother Core

## Epic Overview
Implement Broadway pipelines for multiple AI provider integration (OpenAI, Anthropic, Google) with an adapter pattern for extensibility. Create the distributed Mother Core using Ash Resources to aggregate and manage collective intelligence. This epic establishes the AI integration layer and knowledge management foundation for the xPando platform.

## Business Value
- Enables AI capabilities through multiple provider integrations
- Creates the Mother Core collective intelligence system
- Establishes knowledge sharing and confidence scoring mechanisms
- Provides foundation for AI cost reduction through efficient routing
- Enables the platform's core value proposition of collective learning

## Success Metrics
- Broadway pipelines successfully processing requests from 3+ AI providers
- Mother Core consensus mechanism operational with basic merge strategies
- Knowledge confidence scoring algorithm implemented and tested
- Sub-500ms average response time for cached knowledge queries
- 95% success rate for AI provider requests with retry logic
- Knowledge sharing between nodes demonstrably working

## Technical Requirements
- Broadway pipeline architecture for concurrent AI processing
- Adapter pattern for OpenAI, Anthropic, and Google AI providers
- Mother Core Ash 3.5.36 Resources with consensus state management
- JSONB storage for knowledge content with versioning
- ETS/Mnesia caching for performance optimization
- Phoenix.PubSub for knowledge propagation

## Dependencies
- Epic 1 completed (Foundation Infrastructure)
- AI provider API keys configured
- Broadway and related dependencies installed
- PostgreSQL JSONB support verified

## Risks
- AI provider rate limits affecting performance (Mitigation: Implement intelligent routing and caching)
- Knowledge merge conflicts between nodes (Mitigation: Start with simple last-write-wins, evolve to voting)
- API costs during development (Mitigation: Use mock adapters for testing)

## Stories

### Story 2.1: Broadway Pipeline Infrastructure
**Priority:** P0 - Critical
**Estimate:** 5 points
**Description:** Set up Broadway pipeline architecture for processing AI requests with backpressure and fault tolerance.

**Acceptance Criteria:**
1. Broadway supervisor tree configured in xpando_ai app
2. Pipeline stages defined: producer, processor, batcher
3. Backpressure handling with configurable rate limits
4. Dead letter queue for failed requests
5. Telemetry events for monitoring pipeline health
6. Unit tests for pipeline flow

### Story 2.2: AI Provider Adapter Implementation
**Priority:** P0 - Critical
**Estimate:** 8 points
**Description:** Implement adapter pattern with concrete implementations for OpenAI, Anthropic, and Google AI providers.

**Acceptance Criteria:**
1. Common adapter behaviour defined with callbacks
2. OpenAI adapter with GPT-4 integration
3. Anthropic adapter with Claude integration
4. Google adapter with Gemini integration
5. Configuration for API keys and endpoints
6. Retry logic with exponential backoff
7. Mock adapter for testing

### Story 2.3: Mother Core Resource Implementation
**Priority:** P0 - Critical
**Estimate:** 8 points
**Description:** Create Mother Core Ash Resources for managing distributed consensus and collective intelligence.

**Acceptance Criteria:**
1. MotherCore resource with consensus_state JSONB field
2. Genesis node detection and initialization logic
3. Peer synchronization with Phoenix.PubSub
4. Network version tracking and compatibility checks
5. Consensus algorithm for knowledge acceptance
6. State persistence with ash_postgres

### Story 2.4: Knowledge Resource & Management
**Priority:** P0 - Critical
**Estimate:** 5 points
**Description:** Implement Knowledge Ash Resource with versioning, confidence scoring, and Merkle tree verification.

**Acceptance Criteria:**
1. Knowledge resource with JSONB content storage
2. Confidence scoring calculation as Ash calculation
3. Version tracking with parent references
4. Merkle root generation for content verification
5. Domain categorization for specialized knowledge
6. Relationships to Node and Contribution resources

### Story 2.5: Knowledge Sharing Protocol
**Priority:** P1 - High
**Estimate:** 8 points
**Description:** Build P2P knowledge sharing protocol using Phoenix Channels and PubSub for node communication.

**Acceptance Criteria:**
1. Knowledge broadcast via Phoenix.PubSub topics
2. Selective sharing based on node specializations
3. Bandwidth-aware chunking for large knowledge
4. Acknowledgment and receipt confirmation
5. Conflict detection for concurrent updates
6. Integration tests for multi-node scenarios

### Story 2.6: Knowledge Merge Strategies
**Priority:** P1 - High
**Estimate:** 5 points
**Description:** Implement merge strategies for combining knowledge from multiple nodes with confidence weighting.

**Acceptance Criteria:**
1. Last-write-wins strategy for simple conflicts
2. Weighted voting based on node reputation
3. Domain-specific merge rules
4. Confidence score recalculation after merge
5. Audit trail of merge decisions
6. Configurable strategy selection

### Story 2.7: Caching Layer Implementation
**Priority:** P1 - High
**Estimate:** 3 points
**Description:** Set up ETS/Mnesia caching for frequently accessed knowledge to meet sub-500ms latency requirements.

**Acceptance Criteria:**
1. ETS tables for hot knowledge caching
2. TTL-based cache invalidation
3. Cache warming on node startup
4. Memory limits with LRU eviction
5. Cache hit/miss metrics via Telemetry
6. Benchmarks showing <500ms retrieval

### Story 2.8: AI Request Router
**Priority:** P2 - Medium
**Estimate:** 5 points
**Description:** Build intelligent routing system to select optimal AI provider based on request type and cost.

**Acceptance Criteria:**
1. Request classification by complexity
2. Provider selection based on capabilities
3. Cost tracking per provider
4. Fallback routing on provider failure
5. Load balancing across providers
6. A/B testing framework for optimization

## Definition of Done
- All stories completed and accepted
- Broadway pipelines processing requests successfully
- Mother Core consensus working across multiple nodes
- Knowledge sharing demonstrably functional
- Performance benchmarks met (<500ms for cached queries)
- Integration tests for multi-node scenarios
- Documentation for AI provider setup
- No critical security issues in API handling