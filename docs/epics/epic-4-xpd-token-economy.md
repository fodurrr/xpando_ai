# Epic 4: XPD Token Economy & Incentive Layer

## Epic Overview
Create the Solana blockchain-based XPD token economy that incentivizes knowledge contributions and node participation. Implement wallet integration, contribution tracking with quality scoring, and token distribution mechanisms. This epic establishes the economic layer that sustains the network's growth and rewards valuable contributions.

## Business Value
- Creates sustainable economic model for network growth
- Incentivizes high-quality knowledge contributions
- Rewards node operators for infrastructure provision
- Establishes foundation for future monetization
- Aligns participant incentives with network success

## Success Metrics
- XPD token successfully deployed on Solana devnet/mainnet
- Wallet connection working for 95%+ of users
- Contribution rewards distributed within 1 hour
- Quality scoring algorithm achieving 80%+ accuracy
- Token distribution mechanisms operating without manual intervention
- Gas fees optimized below $0.01 per transaction

## Technical Requirements
- Solana Web3.js integration
- SPL Token program for XPD token
- Phoenix LiveView wallet components
- Contribution tracking via Ash Resources
- Quality scoring algorithms
- Token distribution scheduler

## Dependencies
- Epics 1, 2, 3 completed
- Solana RPC endpoint access
- Wallet browser extensions (Phantom, Solflare)
- Token economics model finalized

## Risks
- Solana network congestion affecting transactions (Mitigation: Implement retry logic and queuing)
- Token value volatility (Mitigation: Initial distribution controls and vesting)
- Gaming of quality scoring system (Mitigation: Multi-factor validation and reputation)

## Stories

### Story 4.1: Solana Integration Setup
**Priority:** P0 - Critical
**Estimate:** 5 points
**Description:** Set up Solana blockchain integration with Web3.js and configure RPC endpoints for development and production.

**Acceptance Criteria:**
1. Solana Web3.js integrated in xpando_blockchain app
2. RPC endpoints configured for devnet and mainnet
3. Connection management with fallback endpoints
4. Transaction builder utilities
5. Wallet adapter abstraction layer
6. Integration tests using devnet

### Story 4.2: XPD Token Creation
**Priority:** P0 - Critical
**Estimate:** 5 points
**Description:** Deploy XPD token on Solana using SPL Token program with proper metadata and initial supply configuration.

**Acceptance Criteria:**
1. XPD token created with SPL Token program
2. Token metadata (name, symbol, decimals) configured
3. Initial supply minted to treasury account
4. Token account management utilities
5. Mint authority properly secured
6. Token verified on Solana explorers

### Story 4.3: Wallet Integration LiveView Components
**Priority:** P0 - Critical
**Estimate:** 8 points
**Description:** Build Phoenix LiveView components for wallet connection, balance display, and transaction signing.

**Acceptance Criteria:**
1. Wallet connection button component
2. Support for Phantom and Solflare wallets
3. Balance display with auto-refresh
4. Transaction signing flow
5. Wallet disconnection handling
6. Mobile wallet adapter support

### Story 4.4: Contribution Tracking System
**Priority:** P0 - Critical
**Estimate:** 5 points
**Description:** Implement contribution tracking using Ash Resources with quality metrics and validation counts.

**Acceptance Criteria:**
1. Contribution resource with quality scoring
2. Validation tracking by peer nodes
3. Contribution history per node
4. Merkle proof generation for contributions
5. Time-based contribution windows
6. Contribution analytics dashboard

### Story 4.5: Quality Scoring Algorithm
**Priority:** P1 - High
**Estimate:** 8 points
**Description:** Develop multi-factor quality scoring algorithm for evaluating knowledge contributions.

**Acceptance Criteria:**
1. Factors: peer validation, usage frequency, accuracy
2. Weighted scoring with configurable weights
3. Anti-gaming mechanisms
4. Score decay over time for freshness
5. Specialization bonus for domain experts
6. A/B testing framework for optimization

### Story 4.6: Token Distribution Engine
**Priority:** P1 - High
**Estimate:** 8 points
**Description:** Build automated token distribution engine with scheduling, batching, and treasury management.

**Acceptance Criteria:**
1. Distribution scheduler with Oban
2. Batch transactions for gas optimization
3. Treasury account management
4. Distribution rules configuration
5. Vesting schedules for large rewards
6. Distribution audit trail

### Story 4.7: Reward Calculation Service
**Priority:** P1 - High
**Estimate:** 5 points
**Description:** Create service for calculating XPD rewards based on contributions, quality scores, and network parameters.

**Acceptance Criteria:**
1. Reward calculation based on quality scores
2. Network-wide reward pool management
3. Dynamic reward adjustment based on supply
4. Bonus multipliers for early contributors
5. Reward caps to prevent exploitation
6. Calculation transparency via logs

### Story 4.8: Token Economics Dashboard
**Priority:** P2 - Medium
**Estimate:** 3 points
**Description:** Build dashboard for monitoring token economics, distribution metrics, and network health.

**Acceptance Criteria:**
1. Total supply and circulation metrics
2. Distribution rate charts
3. Top contributor leaderboard
4. Network value metrics
5. Token velocity tracking
6. Export functionality for analysis

## Definition of Done
- All stories completed and accepted
- XPD token deployed and functional on Solana
- Wallet integration tested across browsers
- Contribution tracking accurately recording data
- Quality scoring algorithm validated
- Token distribution operating automatically
- Security audit completed for smart contracts
- Documentation for token economics model