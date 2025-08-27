# Technical Assumptions

## Repository Structure: Monorepo
Elixir umbrella application structure organizing core, web, and node components within a single repository. This approach supports the integrated development workflow needed for distributed AI coordination while maintaining clear separation between Phoenix web interface, core AI logic, and P2P networking components.

## Service Architecture
**Monolith with Distributed Actor Model**: Single Elixir/OTP application leveraging GenServers and supervision trees for fault tolerance, with BEAM distribution enabling P2P node communication. The Mother Core operates as distributed state managed through Ash Resources with PostgreSQL persistence, while individual AI nodes run as supervised processes within the same application boundary.

## Testing Requirements
**Unit + Integration Testing**: Comprehensive testing pyramid including unit tests for Ash Resources and business logic, integration tests for AI provider adapters and P2P communication, plus property-based testing for distributed consensus mechanisms. Manual testing convenience methods for complex network scenarios and blockchain integration validation.

## Additional Technical Assumptions and Requests

**Core Framework Stack:**
- **Elixir/OTP with Phoenix Framework**: Leveraging BEAM VM's distributed computing capabilities and fault tolerance
- **Ash Framework Centricity**: All domain logic, data modeling, authentication, and API layers built using Ash ecosystem
- **ash_postgres**: Exclusive database interaction layer ensuring ACID compliance for distributed knowledge management
- **ash_authentication**: Complete user and node identity management with authorization policies
- **Phoenix LiveView + DaisyUI**: Real-time UI without JavaScript complexity, beautiful components from day one

**AI and Data Pipeline:**
- **Broadway Pipelines**: All AI provider integrations (OpenAI, Anthropic, Google) through Broadway for backpressure handling
- **Oban Background Jobs**: Asynchronous knowledge processing, token distribution, and network maintenance tasks
- **ETS/Mnesia Hot Caching**: In-memory knowledge caching for sub-500ms inference requirements
- **S3-Compatible Storage**: Large knowledge objects and model artifacts stored externally

**Blockchain Integration:**
- **Solana SPL Token Program**: XPD token creation and basic distribution without complex smart contracts in MVP
- **Anchor Framework**: Future smart contract development for advanced tokenomics and governance
- **Wallet Integration**: Solana wallet connectivity through LiveView components

**Infrastructure and Deployment:**
- **Kubernetes Orchestration**: Container orchestration for distributed node deployment
- **Fly.io Initial Deployment**: Fast deployment and scaling for MVP phase with AWS migration path
- **libcluster**: Automatic node discovery and clustering for P2P network formation
- **Phoenix Channels**: Real-time communication layer for knowledge sharing and status updates

**Security and Compliance:**
- **ash_authentication Policies**: All access control and authorization managed through Ash policy framework
- **End-to-End Encryption**: Sensitive knowledge transfer protected via encrypted channels
- **GDPR Compliance**: Ash audit logging and data management for regulatory requirements