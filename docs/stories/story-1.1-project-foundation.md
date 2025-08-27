# Story 1.1: Project Foundation & Core Domain Setup

**Epic:** Foundation & Proof of Learning Infrastructure  
**Story ID:** 1.1  
**Priority:** Must Have  
**Estimate:** 8 story points  

## User Story
**As a developer,**  
**I want a complete Elixir umbrella project with Ash Framework integration,**  
**so that I can build distributed AI functionality on solid architectural foundations.**

## Acceptance Criteria
1. Elixir umbrella application created with core, web, and node apps properly structured
2. Phoenix Framework integrated with LiveView capabilities and DaisyUI/Tailwind CSS styling
3. Ash Framework ecosystem fully configured including ash_postgres, ash_authentication, ash_phoenix
4. PostgreSQL database configured with Ash migrations for core domain entities
5. Basic CI/CD pipeline established with testing, linting, and deployment automation
6. Development environment fully documented with setup instructions
7. Core domain models defined as Ash Resources: Node, Knowledge, Contribution entities

## Technical Requirements
- Elixir 1.18+
- Phoenix 1.8+
- Ash Framework 3.5+
- PostgreSQL 16+
- DaisyUI 4.4+ with Tailwind CSS 3.4+

## Definition of Done
- [ ] Umbrella project structure created and documented
- [ ] All dependencies installed and configured
- [ ] Database migrations created and tested
- [ ] Core Ash Resources defined with proper relationships
- [ ] Development setup documented in README
- [ ] All tests passing
- [ ] Code review completed

## Dependencies
None - This is the foundation story

## Technical Implementation

### Umbrella Project Structure
Create the following umbrella application structure following `docs/architecture/unified-project-structure.md`:

**Root project files:**
- `mix.exs` - Root umbrella project definition with shared dependencies
- `config/` - Environment configurations (dev.exs, prod.exs, runtime.exs, test.exs)

**Core Apps to create:**
1. **`apps/xpando_core/`** - Domain logic and Ash Resources
   - `lib/xpando/core/node.ex` - Node Ash Resource
   - `lib/xpando/core/knowledge.ex` - Knowledge Ash Resource  
   - `lib/xpando/core/contribution.ex` - Contribution Ash Resource
   - `lib/xpando.ex` - Main domain module with code interfaces
   - `priv/repo/migrations/` - Database migration files

2. **`apps/xpando_web/`** - Phoenix web interface
   - `lib/xpando_web/endpoint.ex` - Phoenix endpoint configuration
   - `lib/xpando_web/router.ex` - Route definitions
   - `assets/css/app.css` - Tailwind CSS with DaisyUI components
   - `assets/js/app.js` - JavaScript and LiveView hooks

3. **`apps/xpando_node/`** - P2P networking with libcluster
   - `lib/xpando_node/application.ex` - OTP application
   - `lib/xpando_node/supervisor.ex` - Supervision tree

### Key Dependencies (mix.exs)
```elixir
# In root mix.exs
def deps do
  [
    {:ash, "~> 3.5"},
    {:ash_postgres, "~> 2.6"},
    {:ash_authentication, "~> 4.3"},
    {:ash_phoenix, "~> 2.1"},
    {:phoenix, "~> 1.8"},
    {:phoenix_live_view, "~> 1.1"},
    {:libcluster, "~> 3.4"},
    {:postgrex, ">= 0.0.0"},
    {:jason, "~> 1.2"}
  ]
end
```

### Database Configuration
- PostgreSQL 16+ with connection pooling
- Ash-generated migrations for Node, Knowledge, Contribution resources
- Environment-specific database URLs in runtime.exs

### CI/CD Pipeline Setup
Create `.github/workflows/ci.yml` with:
- ExUnit test suite execution
- Credo linting and Dialyzer type checking
- Mix format verification
- Dependency vulnerability scanning with mix audit

## Domain Context

### Core Entities Explained
Based on `docs/architecture/data-models.md`, implement these three foundational Ash Resources:

**Node:** Represents individual AI participants in the P2P network with cryptographic identity, specialization tracking, and reputation scoring. Each node maintains connection state and operational metrics.

**Knowledge:** Stores collective intelligence insights with confidence scoring, content integrity verification via SHA-256 hashing, and validation status tracking. Supports multiple knowledge types (insights, facts, procedures, patterns).

**Contribution:** Junction entity tracking individual node contributions to knowledge with quality assessment and token reward calculations. Enables many-to-many relationships between Nodes and Knowledge.

### Network Architecture
The umbrella structure separates concerns:
- **xpando_core:** Pure domain logic and data persistence using Ash Framework
- **xpando_web:** User interface with Phoenix LiveView for real-time updates
- **xpando_node:** P2P networking infrastructure with libcluster for node discovery

## Key References
- Project structure: `docs/architecture/unified-project-structure.md`
- Ash Resource patterns: `docs/elixir_rules/ash.md#code-structure--organization`
- Coding standards: `docs/elixir_rules/non-negotiable.md`
- Data model specifications: `docs/architecture/data-models.md`
- Technology stack: `docs/architecture/tech-stack.md`

## Testing Strategy

### Test Structure
Following `docs/elixir_rules/ash.md#testing`:

**Unit Tests (ExUnit):**
- Each Ash Resource with comprehensive CRUD operations
- Domain code interface functions
- Policy and authorization rule validation
- Custom changes and validations

**Integration Tests:**
- Cross-app communication between xpando_core and xpando_web
- Database transaction integrity
- Phoenix Channel message handling
- LiveView state management

**Database Tests:**
- Migration up/down operations
- Constraint enforcement
- Index performance verification
- Data integrity across relationships

### Test Environment Setup
```elixir
# In config/test.exs
config :xpando, XPando.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
```

### Success Criteria for Testing
- All ExUnit tests passing with >= 80% code coverage
- No Credo linting violations
- Dialyzer type checking passes without warnings
- Database migrations reversible without data loss
- All Ash Resources properly integrated with Phoenix

## Notes
This story establishes the foundational architecture for the entire xPando platform. All subsequent stories depend on this completion.