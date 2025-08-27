# Unified Project Structure

The Elixir umbrella application structure accommodates both distributed P2P networking and web interface components while maintaining clear separation of concerns.

```
xpando/
├── .github/                          # CI/CD workflows and GitHub configuration
│   └── workflows/
│       ├── ci.yml                    # Continuous integration pipeline
│       ├── deploy.yml                # Deployment to Fly.io
│       └── security.yml              # Security scanning and dependency checks
├── apps/                             # Umbrella application packages
│   ├── xpando_core/                  # Core domain logic and AI coordination
│   │   ├── lib/
│   │   │   ├── xpando/
│   │   │   │   ├── core/             # Ash Resources and domain models
│   │   │   │   │   ├── node.ex
│   │   │   │   │   ├── knowledge.ex
│   │   │   │   │   └── contribution.ex
│   │   │   │   ├── mother_core/      # Distributed knowledge engine
│   │   │   │   │   ├── consensus.ex
│   │   │   │   │   └── validation.ex
│   │   │   │   ├── ai/               # AI provider integration
│   │   │   │   │   ├── provider_hub.ex
│   │   │   │   │   └── providers/
│   │   │   │   │       ├── openai.ex
│   │   │   │   │       ├── anthropic.ex
│   │   │   │   │       └── google.ex
│   │   │   │   ├── blockchain/       # XPD token management
│   │   │   │   │   ├── token_manager.ex
│   │   │   │   │   └── solana_rpc.ex
│   │   │   │   ├── specialization/   # Expert node management
│   │   │   │   │   └── engine.ex
│   │   │   │   └── node_network/     # P2P coordination
│   │   │   │       └── manager.ex
│   │   │   └── xpando.ex
│   │   ├── test/                     # Core domain tests
│   │   ├── priv/
│   │   │   └── repo/
│   │   │       └── migrations/       # Database migrations
│   │   └── mix.exs
│   ├── xpando_web/                   # Phoenix web interface and real-time UI
│   │   ├── lib/
│   │   │   ├── xpando_web/
│   │   │   │   ├── live/             # Phoenix LiveView components
│   │   │   │   │   ├── dashboard_live.ex
│   │   │   │   │   ├── network_live.ex
│   │   │   │   │   └── node_live.ex
│   │   │   │   ├── channels/         # Phoenix Channels for real-time P2P
│   │   │   │   │   ├── node_network_channel.ex
│   │   │   │   │   └── mother_core_channel.ex
│   │   │   │   ├── controllers/      # HTTP controllers and API endpoints
│   │   │   │   ├── components/       # DaisyUI-based UI components
│   │   │   │   ├── grpc/             # gRPC service implementations
│   │   │   │   │   ├── node_service.ex
│   │   │   │   │   ├── knowledge_service.ex
│   │   │   │   │   └── contribution_service.ex
│   │   │   │   └── router.ex
│   │   │   ├── xpando_web.ex
│   │   │   └── endpoint.ex
│   │   ├── assets/                   # Frontend assets and Tailwind CSS
│   │   │   ├── css/
│   │   │   │   └── app.css           # Main stylesheet with DaisyUI
│   │   │   ├── js/
│   │   │   │   ├── app.js            # Main JavaScript entry
│   │   │   │   └── hooks/            # LiveView JavaScript hooks
│   │   │   └── vendor/
│   │   ├── test/                     # Web interface tests
│   │   └── mix.exs
│   └── xpando_node/                  # P2P node networking and libcluster
│       ├── lib/
│       │   ├── xpando_node/
│       │   │   ├── cluster/          # Node discovery and clustering
│       │   │   │   └── strategy.ex
│       │   │   ├── supervisor.ex     # OTP supervision tree
│       │   │   └── application.ex
│       │   └── xpando_node.ex
│       ├── test/
│       └── mix.exs
├── config/                           # Application configuration
│   ├── config.exs                    # Base configuration
│   ├── dev.exs                       # Development environment
│   ├── prod.exs                      # Production environment
│   ├── runtime.exs                   # Runtime configuration
│   └── test.exs                      # Test environment
├── proto/                            # Protocol Buffer definitions
│   ├── xpando.proto                  # Main gRPC service definitions
│   └── generated/                    # Generated protobuf code
│       ├── elixir/
│       ├── python/
│       └── typescript/
├── priv/                            # Private application resources
│   ├── static/                       # Static web assets
│   ├── gettext/                      # Internationalization
│   └── repo/
│       ├── migrations/               # Database migration files
│       └── seeds.exs                 # Database seed data
├── scripts/                          # Deployment and utility scripts
│   ├── deploy.sh                     # Production deployment script
│   ├── setup.sh                      # Development environment setup
│   └── benchmark.ex                  # Performance benchmarking
├── docs/                            # Project documentation
│   ├── prd.md                       # Product Requirements Document
│   ├── architecture.md              # This architecture document
│   └── api/                         # Generated API documentation
├── .env.example                      # Environment variables template
├── .gitignore                       # Git ignore patterns
├── docker-compose.yml               # Local development services
├── Dockerfile                       # Container image definition
├── fly.toml                         # Fly.io deployment configuration
├── mix.exs                          # Root mix project definition
└── README.md                        # Project overview and setup
```
