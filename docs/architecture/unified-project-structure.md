# Unified Project Structure

```plaintext
xpando/
├── devbox.json                 # DevBox Shell configuration
├── devbox.lock                 # Locked dependency versions
├── .github/                    # CI/CD workflows
│   └── workflows/
│       ├── ci.yaml            # Test and quality checks
│       └── deploy.yaml        # Deployment pipeline
├── apps/                       # Umbrella applications
│   ├── xpando_core/           # Core domain logic
│   │   ├── lib/
│   │   │   └── xpando/
│   │   │       ├── core/      # Ash Resources
│   │   │       │   ├── resources/
│   │   │       │   └── registry.ex
│   │   │       ├── mother_core/
│   │   │       └── repo.ex    # Ecto Repo
│   │   ├── priv/
│   │   │   └── repo/
│   │   │       └── migrations/
│   │   └── mix.exs
│   ├── xpando_web/            # Phoenix web interface
│   │   ├── lib/
│   │   │   └── xpando_web/
│   │   │       ├── components/
│   │   │       ├── live/
│   │   │       ├── controllers/
│   │   │       ├── router.ex
│   │   │       └── endpoint.ex
│   │   ├── assets/            # Frontend assets
│   │   │   ├── css/
│   │   │   └── js/
│   │   ├── priv/
│   │   │   └── static/
│   │   └── mix.exs
│   ├── xpando_node/           # P2P node implementation
│   │   ├── lib/
│   │   │   └── xpando_node/
│   │   │       ├── manager.ex
│   │   │       ├── discovery.ex
│   │   │       └── protocol.ex
│   │   └── mix.exs
│   ├── xpando_ai/             # AI provider integration
│   │   ├── lib/
│   │   │   └── xpando_ai/
│   │   │       ├── broadway/
│   │   │       └── adapters/
│   │   └── mix.exs
│   └── xpando_blockchain/     # Solana integration
│       ├── lib/
│       │   └── xpando_blockchain/
│       │       ├── xpd_token.ex
│       │       └── wallet.ex
│       └── mix.exs
├── config/                     # Configuration files
│   ├── config.exs             # Base configuration
│   ├── dev.exs                # Development config
│   ├── test.exs               # Test config
│   ├── prod.exs               # Production config
│   └── runtime.exs            # Runtime configuration
├── infrastructure/             # IaC definitions
│   ├── terraform/
│   │   ├── modules/
│   │   ├── environments/
│   │   └── main.tf
│   └── kubernetes/
│       ├── base/
│       └── overlays/
├── scripts/                    # Utility scripts
│   ├── setup.sh               # Initial setup
│   ├── deploy.sh              # Deployment script
│   └── migrate.sh             # Database migrations
├── docs/                       # Documentation
│   ├── prd/                   # Product requirements (sharded)
│   ├── architecture/          # Architecture docs (sharded)
│   │   ├── index.md          # Main architecture index
│   │   ├── tech-stack.md     # Technology choices
│   │   ├── development-workflow.md
│   │   └── ...               # Other sharded sections
│   └── api/                   # API documentation
├── .env.example               # Environment template
├── package.json               # pnpm workspace config (if needed)
├── pnpm-workspace.yaml        # pnpm workspace definition
├── mix.exs                    # Umbrella project file
├── mix.lock                   # Dependency lock file
└── README.md                  # Project documentation
```