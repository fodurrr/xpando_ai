# Epic 1: Foundation Infrastructure & Core Domain

## Epic Overview
Establish the foundational Elixir/Phoenix project structure with Ash Framework integration, implementing core domain models (Nodes, Knowledge, Contributions, MotherCore) and basic CRUD operations. This epic focuses on setting up the essential infrastructure and domain layer that all future features will build upon.

## Business Value
- Establishes the technical foundation for the entire xPando platform
- Enables rapid development of subsequent features with proper architecture
- Provides immediate value through admin dashboard for system monitoring
- Creates the data persistence layer required for all AI and P2P functionality

## Success Metrics
- All core Ash Resources (Node, Knowledge, Contribution, MotherCore) fully implemented with CRUD operations
- PostgreSQL database properly configured with ash_postgres integration
- Phoenix application successfully deployed and accessible
- Admin dashboard functional with basic resource management
- All unit tests passing with >80% code coverage
- Development environment reproducible across team

## Technical Requirements
- Elixir 1.18.1 with Phoenix 1.8.0 framework
- Ash 3.5.36 framework with ash_postgres 2.6.16, ash_authentication 4.9.9
- PostgreSQL 16+ database with proper migrations
- DaisyUI 4.12.14 components integrated with Phoenix LiveView 1.1+
- ETS/Mnesia caching layer configured
- Telemetry and logging infrastructure operational

## Dependencies
- DevBox shell environment configured
- PostgreSQL database server available
- Elixir/Erlang runtime installed
- Git repository initialized

## Risks
- Team learning curve with Ash Framework (Mitigation: Start with simple resources, leverage documentation)
- Database schema changes during development (Mitigation: Use Ash migrations for flexibility)
- Performance baseline not established (Mitigation: Implement telemetry early)

## Stories

### Story 1.1: Project Bootstrap & Ash Setup
**Priority:** P0 - Critical
**Estimate:** 5 points
**Description:** Initialize Phoenix umbrella application with Ash framework integration, configure core dependencies, and establish project structure.

**Acceptance Criteria:**
1. Phoenix umbrella application created with proper app separation (xpando_core, xpando_web)
2. Ash 3.5.36 framework integrated with ash_postgres 2.6.16, ash_authentication 4.9.9 dependencies
3. PostgreSQL database configured with connection pooling
4. DevBox shell configuration working for all developers
5. Basic CI/CD pipeline with GitHub Actions
6. Project compiles without warnings

### Story 1.2: Core Domain Models Implementation
**Priority:** P0 - Critical  
**Estimate:** 8 points
**Description:** Implement Node, Knowledge, and Contribution Ash Resources with full CRUD operations and relationships.

**Acceptance Criteria:**
1. Node resource created with all attributes from data model (id, name, status, specializations, reputation_score, etc.)
2. Knowledge resource implemented with JSONB content field and version tracking
3. Contribution resource tracking node contributions with quality scoring
4. All relationships properly defined between resources
5. Database migrations generated and applied successfully
6. Basic validations and calculations working

### Story 1.3: MotherCore Resource & State Management
**Priority:** P0 - Critical
**Estimate:** 5 points
**Description:** Create MotherCore Ash Resource for managing distributed consensus state and network coordination.

**Acceptance Criteria:**
1. MotherCore resource with consensus_state JSONB field
2. Genesis node designation logic implemented
3. Network version tracking functionality
4. Peer management capabilities
5. State synchronization timestamps
6. Unit tests for state management logic

### Story 1.4: Authentication System Setup
**Priority:** P1 - High
**Estimate:** 5 points
**Description:** Implement ash_authentication for both user access and node identity management.

**Acceptance Criteria:**
1. User authentication with email/password
2. Node authentication with API tokens
3. Role-based access control (admin, node, user)
4. Session management with secure cookies
5. Password reset functionality
6. Authentication tests passing

### Story 1.5: Admin Dashboard with ash_admin
**Priority:** P1 - High
**Estimate:** 3 points
**Description:** Configure and deploy ash_admin dashboard for system monitoring and resource management.

**Acceptance Criteria:**
1. ash_admin integrated and accessible at /admin
2. All core resources visible and manageable
3. Custom admin actions for node management
4. Filtering and search functionality working
5. Proper authorization for admin access
6. Dashboard responsive on mobile devices

### Story 1.6: Phoenix LiveView Basic UI Shell
**Priority:** P1 - High
**Estimate:** 5 points
**Description:** Create the basic Phoenix LiveView application shell with DaisyUI components and navigation.

**Acceptance Criteria:**
1. LiveView application structure established
2. DaisyUI components integrated with Tailwind CSS
3. Basic navigation menu with routing
4. Home dashboard with placeholder content
5. Responsive layout for desktop/mobile
6. Dark mode toggle functional

### Story 1.7: Telemetry & Monitoring Setup
**Priority:** P2 - Medium
**Estimate:** 3 points
**Description:** Implement comprehensive telemetry, logging, and monitoring infrastructure.

**Acceptance Criteria:**
1. Telemetry events configured for all resources
2. Prometheus metrics endpoint exposed
3. Structured logging with Logger
4. Performance metrics for database queries
5. Error tracking and alerting configured
6. Basic dashboard for metrics visualization

### Story 1.8: Development Tooling & Testing Infrastructure
**Priority:** P2 - Medium
**Estimate:** 3 points
**Description:** Establish development tooling, testing patterns, and code quality standards.

**Acceptance Criteria:**
1. ExUnit test suite configured with factories
2. Mox for mocking external dependencies
3. Code formatting with mix format
4. Dialyzer for type checking
5. Credo for code quality analysis
6. Pre-commit hooks configured

## Definition of Done
- All stories completed and accepted
- Code review completed for all changes
- Unit tests written and passing (>80% coverage)
- Integration tests for critical paths
- Documentation updated (README, architecture docs)
- No critical security vulnerabilities
- Performance benchmarks established
- Deployed to staging environment