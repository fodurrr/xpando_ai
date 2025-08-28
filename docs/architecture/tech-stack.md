# Tech Stack

## Technology Stack Table

| Category | Technology | Version | Purpose | Rationale |
|----------|------------|---------|---------|-----------|
| Frontend Language | Elixir/HEEx | 1.17+ | LiveView templates and components | Native integration with Phoenix LiveView |
| Frontend Framework | Phoenix LiveView | 1.7+ | Real-time server-rendered UI | Eliminates API complexity, maintains real-time updates |
| UI Component Library | DaisyUI | 4.x | Pre-built Tailwind components | Beautiful components with minimal configuration |
| State Management | LiveView State | Built-in | Server-side state management | Simplified state without frontend complexity |
| Backend Language | Elixir | 1.17+ | Core application logic | Distributed computing and fault tolerance |
| Backend Framework | Phoenix + Ash | 1.7+ / 3.x | Web framework and domain layer | Comprehensive framework with built-in auth and APIs |
| API Style | GraphQL via AshGraphql | 3.x | External API for nodes | Flexible querying for diverse node requirements |
| Database | PostgreSQL | 16+ | Primary data store | ACID compliance for distributed consensus |
| Cache | ETS/Mnesia | Built-in | In-memory caching | Sub-500ms inference requirement |
| File Storage | S3-Compatible | Latest | Knowledge artifacts storage | Scalable object storage for large models |
| Authentication | ash_authentication | 3.x | User and node authentication | Integrated auth with policy enforcement |
| Frontend Testing | ExUnit + Wallaby | Built-in | LiveView and integration tests | Native Elixir testing with browser automation |
| Backend Testing | ExUnit + Mox | Built-in | Unit and integration tests | Comprehensive testing with mocking support |
| E2E Testing | Wallaby | 0.30+ | Browser automation tests | Headless Chrome testing for user flows |
| Build Tool | Mix | Built-in | Build and dependency management | Native Elixir tooling |
| Bundler | ESBuild | 0.17+ | Asset bundling | Fast JavaScript/CSS bundling |
| IaC Tool | Terraform | 1.5+ | Infrastructure provisioning | Declarative infrastructure management |
| CI/CD | GitHub Actions | Latest | Continuous integration/deployment | Native GitHub integration |
| Monitoring | Telemetry + Prometheus | Latest | Metrics collection | Built-in Elixir observability |
| Logging | Logger + ElasticSearch | Built-in | Centralized logging | Structured logging with search |
| CSS Framework | Tailwind CSS | 3.x | Utility-first CSS | Rapid UI development with DaisyUI |
| Development Environment | DevBox Shell | Latest | Reproducible dev environments | Consistent tooling across all developers |
| Package Manager | pnpm | Latest | Fast, disk-space efficient package manager | Better performance than npm/yarn |