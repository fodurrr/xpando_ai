# Source Tree Structure

This document defines the comprehensive directory structure and file organization for the xPando project, following Elixir/Phoenix umbrella application patterns with Ash Framework integration.

## Project Overview

xPando is structured as an **Umbrella Application** with three main applications:
- `xpando_core` - Core domain logic and Ash resources
- `xpando_web` - Phoenix web interface and LiveView components  
- `xpando_node` - P2P network node functionality

## Root Directory Structure

```
xpando/
├── README.md                    # Project overview and setup instructions
├── mix.exs                      # Umbrella project configuration
├── mix.lock                     # Dependency version lock file
├── xpando.code-workspace        # VS Code workspace configuration
├── devbox.json                  # Development environment configuration
├── devbox.lock                  # Development environment lock file
├── .bmad-core/                  # BMAD agent system configuration
├── .ai/                         # AI debugging and development logs
├── .github/                     # GitHub Actions and workflows
├── config/                      # Application configuration
├── deps/                        # Compiled dependencies (git ignored)
├── _build/                      # Build artifacts (git ignored)
├── apps/                        # Umbrella applications
└── docs/                        # Project documentation
```

## Configuration Directory (`config/`)

```
config/
├── config.exs          # Base configuration for all environments
├── dev.exs             # Development environment settings
├── prod.exs            # Production environment settings
├── runtime.exs         # Runtime configuration (secrets, env vars)
└── test.exs            # Test environment settings
```

**Configuration Responsibilities:**
- Database connections and repository settings
- Phoenix endpoint and server configuration
- Ash domain and resource registry
- Authentication providers and strategies
- External service integrations (AI, blockchain)
- Environment-specific optimizations

## Documentation Directory (`docs/`)

```
docs/
├── architecture/           # Technical architecture documentation
│   ├── index.md           # Architecture overview and navigation
│   ├── introduction.md    # Project introduction and concepts
│   ├── high-level-architecture.md  # System architecture overview
│   ├── components.md      # Component interaction diagrams
│   ├── core-workflows.md  # Business process workflows
│   ├── data-models.md     # Domain model definitions
│   ├── database-schema.md # Database structure and relationships
│   ├── api-specification.md # API contracts and specifications
│   ├── external-apis.md   # Third-party service integrations
│   ├── unified-project-structure.md # Project organization principles
│   ├── tech-stack.md      # Technology choices and versions
│   ├── coding-standards.md # Development standards and conventions
│   └── source-tree.md     # This file - directory structure guide
├── elixir_rules/          # Elixir and framework specific guidelines
│   ├── non-negotiable.md  # Absolute development requirements
│   ├── general-guidelines.md # Best practices and conventions
│   ├── ash.md             # Ash Framework usage patterns
│   ├── ash_ai.md          # AI integration with Ash resources
│   ├── ash_oban.md        # Background job processing
│   ├── ash_phoenix.md     # Phoenix integration patterns
│   ├── ash_postgres.md    # Database layer configuration
│   └── igniter.md         # Code generation and AST manipulation
├── prd/                   # Product Requirements Documentation
│   ├── index.md           # PRD overview and navigation
│   ├── goals-and-background-context.md # Project objectives
│   ├── requirements.md    # Functional and non-functional requirements
│   ├── technical-assumptions.md # Platform and technology constraints
│   ├── user-interface-design-goals.md # UX/UI design principles
│   ├── epic-list.md       # High-level feature epics
│   ├── epic-1-foundation-proof-of-learning.md # Core platform epic
│   ├── epic-2-ai-provider-mother-core.md # AI integration epic
│   ├── epic-3-expert-specialization-scaling.md # Scaling epic
│   ├── epic-4-xpd-token-economy.md # Token economy epic
│   ├── next-steps.md      # Implementation roadmap
│   └── checklist-results-report.md # Validation and approval status
└── stories/               # Development stories and implementation guides
    ├── index.md           # Stories overview and status tracking
    ├── story-1.1-project-foundation.md # Project setup and infrastructure
    ├── story-1.2-authentication.md # User authentication system
    ├── story-1.3-p2p-network-communication.md # Peer-to-peer networking
    ├── story-1.4-liveview-dashboard.md # Real-time dashboard interface
    ├── story-1.5-knowledge-representation-storage.md # Knowledge management
    ├── story-1.6-cicd-pipeline.md # Continuous integration/deployment
    ├── story-1.7-deployment-infrastructure.md # Production infrastructure
    ├── story-1.8-external-service-integration.md # Third-party APIs
    ├── story-1.9-security-credential-management.md # Security implementation
    ├── story-1.10-api-documentation.md # API documentation generation
    ├── story-1.11-accessibility-ui-enhancement.md # Accessibility features
    └── story-1.12-collective-intelligence-proof.md # Proof of concept validation
```

## Apps Directory (`apps/`)

### Core Application (`apps/xpando_core/`)

The core domain logic and business rules, implemented using Ash Framework.

```
apps/xpando_core/
├── README.md              # Core application overview
├── mix.exs                # Core application dependencies
├── lib/
│   ├── xpando_core.ex     # Application entry point
│   ├── xpando_core/
│   │   └── application.ex # OTP application supervisor
│   ├── xpando/            # Main namespace for domain logic
│   │   ├── repo.ex        # Database repository configuration
│   │   └── core/          # Core domain implementations
│   │       ├── contribution.ex      # Contribution domain logic
│   │       ├── contribution/
│   │       │   └── validate_contribution_data.ex # Data validation
│   │       ├── knowledge.ex         # Knowledge management domain
│   │       ├── knowledge/
│   │       │   └── validate_content_hash.ex # Content integrity validation
│   │       ├── node.ex              # Network node domain
│   │       └── node/
│   │           └── validate_public_key.ex # Cryptographic validation
├── priv/
│   └── repo/
│       ├── migrations/    # Database schema migrations
│       └── seeds.exs      # Development data seeding
└── test/
    ├── test_helper.exs    # Test configuration and setup
    ├── xpando_core_test.exs # Application-level tests
    ├── support/
    │   ├── data_case.ex   # Database test case helpers
    │   └── factory.ex     # Test data factories
    └── xpando/
        └── core/          # Domain-specific tests
            ├── contribution_test.exs # Contribution domain tests
            ├── knowledge_test.exs    # Knowledge domain tests
            └── node_test.exs         # Node domain tests
```

**Core Domain Organization:**
- **Domains**: High-level business contexts (Knowledge, Network, Blockchain)
- **Resources**: Ash resources representing domain entities
- **Actions**: Business operations on resources (create, read, update, destroy, custom)
- **Calculations**: Computed attributes and derived data
- **Validations**: Custom validation logic and constraints
- **Policies**: Authorization rules and access control

### Web Application (`apps/xpando_web/`)

Phoenix web interface with LiveView for real-time interactions.

```
apps/xpando_web/
├── README.md              # Web application overview
├── mix.exs                # Web application dependencies
├── lib/
│   ├── xpando_web.ex      # Web application entry point
│   ├── xpando_web/
│   │   ├── application.ex # OTP application supervisor
│   │   └── mailer.ex      # Email delivery configuration
│   ├── xpando_web_web.ex  # Web context and imports
│   └── xpando_web_web/    # Phoenix web components
│       ├── components/    # Reusable UI components
│       │   ├── core_components.ex # Base component library
│       │   └── layouts.ex         # Page layout components
│       │   └── layouts/
│       │       ├── app.html.heex  # Main application layout
│       │       └── root.html.heex # Root HTML template
│       ├── controllers/   # HTTP request handlers
│       │   ├── error_html.ex      # Error page rendering
│       │   ├── error_json.ex      # API error responses
│       │   ├── page_controller.ex # Static page controller
│       │   ├── page_html.ex       # Page view helpers
│       │   └── page_html/
│       │       └── home.html.heex # Homepage template
│       ├── endpoint.ex    # Phoenix endpoint configuration
│       ├── gettext.ex     # Internationalization support
│       ├── router.ex      # URL routing configuration
│       └── telemetry.ex   # Application monitoring and metrics
├── assets/                # Frontend assets and build configuration
│   ├── css/
│   │   └── app.css        # Main application styles (Tailwind CSS)
│   ├── js/
│   │   └── app.js         # JavaScript entry point and LiveView setup
│   ├── tailwind.config.js # Tailwind CSS configuration
│   └── vendor/            # Third-party frontend libraries
├── priv/
│   ├── gettext/           # Translation files
│   │   ├── en/
│   │   │   └── LC_MESSAGES/
│   │   │       └── errors.po # English error messages
│   │   └── errors.pot     # Translation template
│   └── static/            # Static web assets
│       ├── favicon.ico    # Website favicon
│       ├── images/
│       │   └── logo.svg   # Application logo
│       └── robots.txt     # Search engine crawler instructions
└── test/
    ├── test_helper.exs    # Test configuration and setup
    ├── support/
    │   └── conn_case.ex   # HTTP connection test helpers
    └── xpando_web_web/    # Web-specific tests
        └── controllers/   # Controller tests
            ├── error_html_test.exs # Error handling tests
            ├── error_json_test.exs # API error tests
            └── page_controller_test.exs # Page controller tests
```

**Web Application Organization:**
- **Controllers**: Handle HTTP requests and coordinate with domains
- **Live Views**: Real-time interactive pages using Phoenix LiveView
- **Components**: Reusable UI components with function components
- **Layouts**: Page structure and common UI elements
- **Assets**: Frontend styling (Tailwind CSS) and JavaScript (LiveView hooks)
- **Static Files**: Images, fonts, and other static resources

### Node Application (`apps/xpando_node/`)

P2P network functionality and node-to-node communication.

```
apps/xpando_node/
├── README.md              # Node application overview
├── mix.exs                # Node application dependencies
├── lib/
│   └── xpando_node.ex     # Node functionality implementation
└── test/
    ├── test_helper.exs    # Test configuration
    └── xpando_node_test.exs # Node functionality tests
```

**Node Application Responsibilities:**
- P2P network discovery and connection management
- Cryptographic key management and identity verification
- Message routing and protocol handling
- Network topology maintenance
- Consensus protocol participation

## Planned Domain Expansion

As development progresses, the core application will expand with additional Ash domains:

### Knowledge Domain (`lib/xpando/knowledge/`)
```
lib/xpando/knowledge/
├── knowledge.ex           # Domain definition
├── resources/             # Ash resources
│   ├── knowledge_item.ex  # Individual knowledge entries
│   ├── validation.ex      # Validation records
│   ├── consensus_result.ex # Consensus outcomes
│   └── expertise_area.ex  # Subject matter expertise
├── calculations/          # Domain calculations
│   ├── confidence_score.ex # Knowledge confidence calculation
│   └── consensus_weight.ex # Validator weight calculation
└── policies/              # Authorization policies
    ├── knowledge_access.ex # Knowledge access control
    └── validation_rights.ex # Validation permission rules
```

### Network Domain (`lib/xpando/network/`)
```
lib/xpando/network/
├── network.ex             # Domain definition
├── resources/             # Ash resources
│   ├── node.ex            # Network nodes
│   ├── connection.ex      # Node connections
│   ├── topology.ex        # Network topology snapshots
│   └── reputation.ex      # Node reputation tracking
├── calculations/          # Domain calculations
│   ├── trust_score.ex     # Node trust calculation
│   └── network_health.ex  # Network status metrics
└── policies/              # Authorization policies
    └── node_management.ex  # Node management permissions
```

### Blockchain Domain (`lib/xpando/blockchain/`)
```
lib/xpando/blockchain/
├── blockchain.ex          # Domain definition
├── resources/             # Ash resources
│   ├── xpd_transaction.ex # XPD token transactions
│   ├── smart_contract.ex  # Smart contract instances
│   └── consensus_record.ex # Blockchain consensus records
├── calculations/          # Domain calculations
│   ├── token_balance.ex   # Account balance calculation
│   └── transaction_fee.ex # Transaction cost calculation
└── policies/              # Authorization policies
    └── transaction_auth.ex # Transaction authorization
```

### AI Integration Domain (`lib/xpando/ai/`)
```
lib/xpando/ai/
├── ai.ex                  # Domain definition
├── resources/             # Ash resources
│   ├── embedding_model.ex # AI model configurations
│   ├── semantic_search.ex # Search functionality
│   └── mcp_server.ex      # Model Context Protocol servers
├── calculations/          # Domain calculations
│   ├── similarity_score.ex # Semantic similarity
│   └── relevance_rank.ex   # Search result ranking
└── policies/              # Authorization policies
    └── ai_access.ex        # AI service access control
```

## Development and Build Structure

### Hidden Directories (Git Ignored)
```
.git/                      # Git version control metadata
_build/                    # Elixir compilation artifacts
deps/                      # Downloaded dependency source code
.elixir_ls/               # Elixir Language Server cache
node_modules/             # NPM dependencies (if any)
```

### Development Tools
```
.bmad-core/               # BMAD agent system configuration
├── core-config.yaml      # Project configuration for agents
├── tasks/                # Reusable development tasks
├── templates/            # Code and document templates
└── checklists/           # Development checklists and validations

.ai/                      # AI development assistance
└── debug-log.md          # AI debugging and decision log
```

## File Naming Conventions

### Elixir Files
- **Modules**: PascalCase (e.g., `XPando.Knowledge.KnowledgeItem`)
- **Files**: snake_case matching module name (e.g., `knowledge_item.ex`)
- **Test Files**: `*_test.exs` suffix
- **Application Files**: Match application name

### Documentation Files
- **Markdown**: kebab-case with `.md` extension
- **Story Files**: `story-{epic}.{story}-{description}.md`
- **Epic Files**: `epic-{number}-{description}.md`

### Configuration Files
- **Environment**: `{env}.exs` (e.g., `dev.exs`, `prod.exs`)
- **Mix Project**: `mix.exs`
- **Application Config**: `config.exs`

## Integration Points

### Database Migrations
All database schema changes are managed through Ecto migrations in:
```
apps/xpando_core/priv/repo/migrations/
```

### Asset Pipeline
Frontend assets are processed through Phoenix's built-in pipeline:
```
apps/xpando_web/assets/ → apps/xpando_web/priv/static/
```

### Testing Infrastructure
- **Unit Tests**: Domain-specific tests in each app's `test/` directory
- **Integration Tests**: Cross-domain tests in core application
- **End-to-End Tests**: Full system tests in web application

This source tree structure supports the xPando project's distributed architecture while maintaining clear separation of concerns and following Elixir/Phoenix best practices with Ash Framework integration.