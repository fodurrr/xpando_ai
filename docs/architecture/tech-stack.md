# Tech Stack

This is the **DEFINITIVE technology selection** for the entire xPando project. All development must use these exact versions. Based on the PRD requirements and platform choices, here's the comprehensive technology stack:

## Technology Stack Table

| Category | Technology | Version | Purpose | Rationale |
|----------|------------|---------|---------|-----------|
| Frontend Language | Elixir (LiveView) | 1.18+ | Server-side rendered frontend | Phoenix LiveView eliminates need for separate frontend language |
| Frontend Framework | Phoenix LiveView | 1.1+ | Server-side rendered real-time UI | Latest version with colocated hooks and keyed comprehensions |
| UI Component Library | DaisyUI | 4.4+ | Beautiful component system | Tailwind-based components with minimal JavaScript overhead |
| State Management | LiveView Assigns + PubSub | Built-in | Server-side state with real-time sync | No client-side state complexity, automatic synchronization |
| Backend Language | Elixir | 1.18+ | Distributed systems development | Latest with type checking and built-in JSON support |
| Backend Framework | Phoenix | 1.8+ | Web application framework | Mature Elixir web framework with excellent LiveView 1.1 integration |
| API Style | Phoenix Channels + gRPC | 1.8+ | Real-time + RPC hybrid | Channels for P2P communication, gRPC for external integrations |
| OTP Runtime | Erlang/OTP | 28+ | BEAM VM runtime | Latest OTP with nominal types and performance improvements |
| Database | PostgreSQL | 16+ | Primary data persistence | ACID compliance required for knowledge integrity |
| Cache | Redis | 7.4+ | Session and query caching | High-performance caching for distributed node coordination |
| File Storage | Fly.io Volumes + S3 | Latest | Large knowledge object storage | Local volumes for speed, S3 for archival and backup |
| Ash Framework | ash | 3.5+ | Domain modeling framework | Latest version with enhanced resource capabilities |
| Database Layer | ash_postgres | 2.6+ | PostgreSQL integration | Latest version 2.6.10 with recent improvements |
| Authentication | ash_authentication | 4.3+ | User and node identity management | Latest version 4.3.3 with OAuth and password strategies |
| Frontend Testing | ExUnit + Wallaby | 1.18+ | Integration testing for LiveView | Native Elixir testing with browser automation |
| Backend Testing | ExUnit + Mox | 1.18+ | Unit and integration testing | Property-based testing for distributed systems |
| E2E Testing | Wallaby + Hound | 1.2+ | Full system testing | Browser-based testing for complete user workflows |
| Build Tool | Mix | 1.18+ | Elixir build system | Latest with lazy module loading and faster compilation |
| Bundler | esbuild (via Phoenix) | 0.23+ | Asset compilation | Fast asset bundling integrated with Phoenix |
| IaC Tool | Fly Launch + Terraform | Latest | Infrastructure management | Fly.io deployment with Terraform for AWS migration |
| CI/CD | GitHub Actions + Fly Deploy | Latest | Automated deployment | GitHub native CI with Fly.io deployment integration |
| Monitoring | Phoenix LiveDashboard + Telemetry | 0.8+ | Real-time system monitoring | Built-in Elixir observability with custom metrics |
| Logging | Logger + LogTail | 1.18+ | Structured logging | Elixir native logging with external aggregation |
| CSS Framework | Tailwind CSS | 3.4+ | Utility-first styling | Consistent design system with minimal CSS overhead |
| gRPC Library | grpcbox | 0.17+ | High-performance RPC framework | Efficient binary protocol for external service communication |
| Protobuf Compiler | protobuf | 3.21+ | Protocol buffer schema compiler | Type-safe service definitions and code generation |
