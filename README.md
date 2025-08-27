# xPando - Distributed AI Knowledge Network

xPando is a decentralized platform for AI-powered collective intelligence, enabling nodes to share, validate, and contribute knowledge through a peer-to-peer network with cryptographic identity and token-based incentives.

## 🏗️ Architecture

xPando is built as an **Elixir umbrella application** with three core apps:

- **`xpando_core`** - Domain logic and Ash Resources for knowledge management
- **`xpando_web`** - Phoenix LiveView web interface with DaisyUI styling  
- **`xpando_node`** - P2P networking infrastructure with libcluster

## 🚀 Quick Start

### Prerequisites

- **Elixir** 1.19-rc+ 
- **Erlang/OTP** 28+
- **PostgreSQL** 16+
- **Node.js** 18+ (for asset compilation)

### Development Setup

1. **Clone the repository:**
   ```bash
   git clone <repository_url>
   cd xpando
   ```

2. **Install dependencies:**
   ```bash
   mix deps.get
   cd apps/xpando_web/assets && npm install
   ```

3. **Setup database:**
   ```bash
   mix ecto.setup
   ```

4. **Start the development server:**
   ```bash
   mix phx.server
   ```

Visit [`localhost:4000`](http://localhost:4000) to see the application.

### Testing

Run the comprehensive test suite:
```bash
# Run all tests
mix test

# Run tests with coverage
mix test --cover

# Run specific app tests
mix cmd --app xpando_core mix test
```

### Code Quality

```bash
# Format code
mix format

# Run static analysis
mix credo --strict

# Type checking
mix dialyzer

# Security audit
mix deps.audit
mix sobelow
```

## 📦 Core Components

### Domain Resources (Ash Framework)

#### 🔐 Node Resource
Represents AI participants in the P2P network:
- **Cryptographic Identity**: Public/private key pairs with signatures
- **Reputation System**: Consensus-based scoring and trust ratings  
- **Network Metrics**: Connection state and operational data
- **Specialization Tracking**: Domain expertise and capabilities

#### 🧠 Knowledge Resource  
Stores validated collective intelligence:
- **Content Integrity**: SHA-256 hashing for verification
- **Validation Workflow**: Multi-stage consensus process
- **Confidence Scoring**: Statistical confidence measurements
- **Quality Metrics**: Relevance, accuracy, and novelty scoring

#### 🤝 Contribution Resource
Junction entity for node-knowledge relationships:
- **Quality Assessment**: Peer review and consensus scoring
- **Token Rewards**: Calculated incentives based on contribution value
- **Impact Tracking**: Citation and usage metrics
- **Consensus Mechanism**: Network agreement on contribution validity

## 🗄️ Database Schema

The application uses PostgreSQL with Ash-generated migrations:

```bash
# Generate and run migrations
mix ash_postgres.generate_migrations
mix ecto.migrate
```

Core tables:
- `nodes` - Network participant data
- `knowledge` - Validated knowledge items  
- `contributions` - Node contribution records

## 🌐 API & Integration

### GraphQL API (Planned)
- Ash GraphQL integration for flexible querying
- Real-time subscriptions via Phoenix Channels

### gRPC Services (Planned)  
- High-performance inter-node communication
- Protocol buffer definitions in `/proto`

## 🔧 Configuration

### Environment Variables

Create `.env` files for different environments:

```bash
# Development (.env.dev)
DATABASE_URL=postgres://postgres:postgres@localhost/xpando_dev
SECRET_KEY_BASE=your_secret_key_here
PHX_HOST=localhost
PHX_PORT=4000

# Test (.env.test)  
DATABASE_URL=postgres://postgres:postgres@localhost/xpando_test

# Production (.env.prod)
DATABASE_URL=your_production_database_url
SECRET_KEY_BASE=your_production_secret_key
PHX_HOST=your_domain.com
```

### Configuration Files

- `config/config.exs` - Base application config
- `config/dev.exs` - Development environment  
- `config/test.exs` - Test environment
- `config/prod.exs` - Production environment
- `config/runtime.exs` - Runtime configuration

## 🚢 Deployment

### Fly.io Deployment

1. **Install Fly.io CLI:**
   ```bash
   curl -L https://fly.io/install.sh | sh
   ```

2. **Initialize Fly app:**
   ```bash
   fly launch
   ```

3. **Deploy:**
   ```bash
   fly deploy
   ```

### Docker

Build and run with Docker:
```bash
docker build -t xpando .
docker run -p 4000:4000 xpando
```

## 🔄 CI/CD Pipeline

GitHub Actions workflows handle:
- **Testing**: ExUnit, integration, and property-based tests
- **Code Quality**: Credo linting, Dialyzer type checking, formatting
- **Security**: Sobelow security analysis, dependency auditing  
- **Deployment**: Automated Fly.io deployment on main branch

## 📁 Project Structure

```
xpando/
├── apps/
│   ├── xpando_core/          # Domain logic & Ash resources
│   │   ├── lib/
│   │   │   └── xpando/
│   │   │       └── core/     # Ash resources
│   │   ├── test/             # Comprehensive test suite
│   │   └── priv/repo/        # Database migrations
│   ├── xpando_web/           # Phoenix web interface
│   │   ├── lib/
│   │   │   └── xpando_web_web/
│   │   │       ├── live/     # LiveView modules
│   │   │       └── components/ # DaisyUI components
│   │   └── assets/           # CSS/JS assets
│   └── xpando_node/          # P2P networking
├── config/                   # Application configuration
├── .github/workflows/        # CI/CD pipelines
├── docs/                     # Project documentation
└── proto/                    # Protocol buffer definitions
```

## 🛠️ Development Workflow

### Adding New Features

1. **Create feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Add Ash resources or extend existing ones:**
   ```bash
   # Generate new resource
   mix ash.gen.resource YourDomain.YourResource
   ```

3. **Write comprehensive tests:**
   ```bash
   # Test your changes
   mix test
   ```

4. **Ensure code quality:**
   ```bash
   mix format
   mix credo --strict
   ```

5. **Submit pull request**

### Database Changes

When modifying Ash resources:
```bash
# Generate migrations
mix ash_postgres.generate_migrations

# Review generated migration
# Edit if necessary

# Run migration  
mix ecto.migrate
```

## 📋 Available Mix Tasks

```bash
# Development
mix setup                 # Set up the project (deps, db, assets)
mix phx.server           # Start Phoenix server
mix ash_postgres.generate_migrations  # Generate Ash migrations

# Testing
mix test                 # Run all tests
mix test.watch          # Run tests in watch mode  
mix test --cover        # Run with coverage report

# Code Quality
mix format              # Format all code
mix credo              # Run static analysis
mix dialyzer           # Run type checking
mix deps.audit         # Audit dependencies
mix sobelow           # Security analysis

# Database
mix ecto.setup         # Create, migrate, and seed database  
mix ecto.reset         # Drop, create, migrate, and seed
mix ecto.migrate       # Run pending migrations
mix ecto.rollback      # Rollback last migration

# Assets
mix assets.setup       # Install asset dependencies
mix assets.build       # Build assets for development
mix assets.deploy      # Build assets for production

# Release
mix release            # Build production release
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Write tests for your changes  
4. Ensure all tests pass and code quality checks pass
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support & Documentation

- **Architecture docs**: `/docs/architecture/`
- **API docs**: Generated with ExDoc (`mix docs`)
- **Ash resources**: Comprehensive inline documentation
- **Issues**: GitHub Issues for bug reports and feature requests

---

Built with ❤️ using **Elixir**, **Phoenix LiveView**, **Ash Framework**, and **DaisyUI**.