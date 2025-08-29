# Claude Code Guidelines for XPando AI Project

## 🚨 CRITICAL: Must Follow These 5 Core Principles

### 1. **MCP Server Tools FIRST - Never Assume, Always Research**
**This is non-negotiable.** Use MCP tools as your primary interface:
- `mcp__tidewave__project_eval` - Execute and test Elixir code in the running app
  - Use `h Module.function` to get documentation for any module or function
- `mcp__tidewave__get_docs` - Get documentation directly
- `mcp__tidewave__search_package_docs` - Search Ash/Phoenix/dependency docs before starting work
- `mcp__tidewave__execute_sql_query` - Query database (for debugging only)
- `mcp__ash_ai__list_generators` - List available Ash generators
- `mcp__tidewave__get_ecto_schemas` - Find all Ash resources quickly
- `mcp__tidewave__get_logs` - Check for runtime errors

**NEVER** start/stop Phoenix - it breaks the MCP connection!

### 2. **Ash Framework Exclusively - Zero Direct Ecto**
This project uses **Ash Framework** for ALL data operations:
- Resources are in `apps/xpando_core/lib/xpando/core/`
- **NEVER** use Ecto schemas, changesets, or Repo directly
- **ALWAYS** use Ash resources, actions, queries, and changes
- Resources must include: `use Ash.Resource`, domain, data_layer, extensions
- Follow existing patterns in User, Node, Knowledge, Contribution, Token resources

### 3. **Elixir Umbrella Boundaries are Sacred**
Respect the three-app architecture:
```
apps/
├── xpando_core/   # Ash resources, business logic, domain
├── xpando_web/    # Phoenix, LiveView, channels, web interface
└── xpando_node/   # P2P networking, distributed system logic
```
- **NEVER** cross boundaries incorrectly
- Core app has NO web dependencies
- Web/Node apps depend on Core, not on each other
- Use proper umbrella inter-app dependencies

### 4. **Generator-First, Then Customize**
Development workflow:
1. **ALWAYS** check for generators first: `mcp__ash_ai__list_generators` or `mix help`
2. Use generators with `--yes` flag to avoid interactive prompts
3. Generate the base code as starting point
4. Customize generated code to fit requirements
5. Follow patterns from generated code in manual implementations

### 5. **Quality Gates Before ANY Completion**
**Mandatory** before marking any task complete:
```bash
mix format                    # Format code
mix credo --strict           # Code quality
mix compile --warnings-as-errors  # Compilation check
mix test apps/xpando_core/test/...  # Run relevant tests
```
After executing code:
- Check compilation: `mix compile`
- Check logs: `mcp__tidewave__get_logs level: "error"`
- Run applicable tests to verify changes work correctly

## Additional Critical Rules

### Resource Naming and Structure
- Ash resources: `XPando.Core.{ResourceName}` (User, Node, Knowledge, etc.)
- Test files mirror source structure: `test/xpando/core/{resource}_test.exs`
- Use DataCase for tests requiring database: `use XPando.DataCase`
- Validators go in subdirectories: `core/resource/validate_something.ex`

### Testing Best Practices
```bash
# Test specific app
mix test apps/xpando_core/test

# Test with timeout for long-running tests  
timeout 30 mix test apps/xpando_core/test/xpando/core/user_test.exs

# Run with seed for reproducible tests
mix test --seed 0
```

### Database and Migrations
- **ONLY** use Ash migrations: `mix ash_postgres.generate_migrations`
- Database setup: `mix ash.setup` (NOT ecto commands)
- Check migration snapshots in `priv/resource_snapshots/`
- Test environment: `MIX_ENV=test mix ash_postgres.migrate`

## Required Documentation to Follow

1. **`docs/frontend_design_principles/frontend-design-principles.md`** - Tailwind/DaisyUI component-first approach
2. **`docs/architecture/`** - System design and patterns
3. **`docs/stories/`** - User stories and implementation details
4. **`docs/qa/`** - Quality gates and testing requirements

## Project Owner Context - Peter

- **Background**: Computer geek since 1984, experienced programmer in multiple languages
- **Learning**: Just starting with Elixir, Phoenix, and Ash Framework
- **Working Style**: Has creative, sometimes breakthrough ideas that may need exploration
- **Communication**: Help improve terminology and explain Elixir/Ash concepts along the way
- **First Resource**: Ask Peter when you don't know something or where to look

## Non-Negotiable Git & GitHub Rules

- **NEVER** commit, push, or create PRs/issues without explicit permission
- **ALWAYS** when you asked to commit **AWLWAYS** commit all files in the project use `git add -A`.
- **ALWAYS** use `gh` CLI for ALL GitHub interactions
- **NO** autonomous git operations - wait for explicit instructions
- This is an **Elixir umbrella project** - all decisions must respect this architecture

## Project Architecture

- **Type**: P2P distributed AI network with XPD token economy  
- **Current Resources**: User, Node, Knowledge, Contribution, Token
- **Frontend**: Tailwind CSS + DaisyUI component-first approach

## Common Commands Reference

```bash
# Ash/Database
mix ash.setup                    # Setup database
mix ash_postgres.generate_migrations  # Generate migrations
mix ash_postgres.migrate         # Run migrations

# Quality & Testing  
mix format                       # Format code
mix credo --strict              # Code quality
mix compile --warnings-as-errors # Strict compilation
mix test                        # Run all tests
mix dialyzer                    # Type checking

# Development
mix phx.server                  # Start Phoenix (DON'T use in MCP)
iex -S mix                      # Interactive shell (DON'T use in MCP)
```

---

**Remember**: This is an Ash-first project. When in doubt, use MCP tools to research. Never make assumptions. Always verify with `mcp__tidewave__project_eval` before implementing.

