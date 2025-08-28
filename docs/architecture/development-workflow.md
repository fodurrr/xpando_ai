# Development Workflow

## Local Development Setup

### Development Environment: DevBox Shell

This project uses **DevBox Shell** for consistent development environments across all developers. DevBox ensures everyone has the exact same versions of all dependencies without conflicts.

### Prerequisites

#### Option 1: Using DevBox (Recommended)
```bash
# Install DevBox if not already installed
curl -fsSL https://get.jetpack.io/devbox | bash

# Enter the DevBox shell (this will install all dependencies automatically)
devbox shell
```

The DevBox environment provides:
- **Node.js** (latest) - Frontend tooling
- **pnpm** (latest) - Package management
- **Erlang** 27.2 - BEAM VM
- **Elixir** 1.18.1 - Core language
- **Claude Code** (latest) - AI-assisted development

#### Option 2: Manual Installation (Not Recommended)
If you cannot use DevBox, manually install these exact versions:
```bash
# Install Elixir 1.18.1
asdf install elixir 1.18.1

# Install Erlang/OTP 27.2
asdf install erlang 27.2

# Install PostgreSQL 16+
brew install postgresql@16

# Install Node.js (latest)
asdf install nodejs latest

# Install pnpm
npm install -g pnpm

# Install Solana CLI (optional for blockchain testing)
sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
```

### Initial Setup
```bash
# Clone repository
git clone https://github.com/xpando/xpando
cd xpando

# Enter DevBox shell (if not already in it)
devbox shell

# Install Elixir dependencies
mix deps.get

# Setup database
mix ecto.setup

# Install frontend assets dependencies using pnpm
cd apps/xpando_web/assets && pnpm install && cd ../../..

# Generate Ash migrations
mix ash_postgres.generate_migrations

# Run migrations
mix ecto.migrate
```

### Development Commands

All commands should be run inside the DevBox shell:

```bash
# Enter DevBox shell first
devbox shell

# Start all services
iex -S mix phx.server

# Start frontend only (LiveView included)
cd apps/xpando_web && mix phx.server

# Start backend only (API and core)
cd apps/xpando_core && iex -S mix

# Run tests
mix test

# Run specific app tests
mix test apps/xpando_core

# Run with code coverage
mix test --cover

# Format code
mix format

# Run dialyzer
mix dialyzer

# Run credo
mix credo
```

## Environment Configuration

### Required Environment Variables
```bash
# Frontend (.env.local) - Phoenix/LiveView specific
PHX_HOST=localhost
PHX_PORT=4000
SECRET_KEY_BASE=generate_with_mix_phx.gen.secret

# Backend (.env) - Core configuration
DATABASE_URL=postgresql://user:pass@localhost/xpando_dev
POOL_SIZE=10
AI_OPENAI_API_KEY=sk-...
AI_ANTHROPIC_API_KEY=sk-ant-...
AI_GOOGLE_API_KEY=...

# Shared - Used by multiple apps
SOLANA_RPC_URL=https://api.devnet.solana.com
SOLANA_WALLET_PRIVATE_KEY=base58_encoded_key
XPD_TOKEN_MINT_ADDRESS=...
P2P_PORT=4369
EPMD_PORT=4370
```