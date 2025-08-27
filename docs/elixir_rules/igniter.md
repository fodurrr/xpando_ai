# Rules for working with Igniter

## Understanding Igniter

Igniter is a code generation and project patching framework that enables semantic manipulation of Elixir codebases. It provides tools for creating intelligent generators that can both create new files and modify existing ones safely. Igniter works with AST (Abstract Syntax Trees) through Sourceror.Zipper to make precise, context-aware changes to your code.

## Available Modules

### Project-Level Modules (`Igniter.Project.*`)

- **`Igniter.Project.Application`** - Working with Application modules and application configuration
- **`Igniter.Project.Config`** - Modifying Elixir config files (config.exs, runtime.exs, etc.)
- **`Igniter.Project.Deps`** - Managing dependencies declared in mix.exs
- **`Igniter.Project.Formatter`** - Interacting with .formatter.exs files
- **`Igniter.Project.IgniterConfig`** - Managing .igniter.exs configuration files
- **`Igniter.Project.MixProject`** - Updating project configuration in mix.exs
- **`Igniter.Project.Module`** - Creating and managing modules with proper file placement
- **`Igniter.Project.TaskAliases`** - Managing task aliases in mix.exs
- **`Igniter.Project.Test`** - Working with test and test support files

### Code-Level Modules (`Igniter.Code.*`)

- **`Igniter.Code.Common`** - General purpose utilities for working with Sourceror.Zipper
- **`Igniter.Code.Function`** - Working with function definitions and calls
- **`Igniter.Code.Keyword`** - Manipulating keyword lists
- **`Igniter.Code.List`** - Working with lists in AST
- **`Igniter.Code.Map`** - Manipulating maps
- **`Igniter.Code.Module`** - Working with module definitions and usage
- **`Igniter.Code.String`** - Utilities for string literals
- **`Igniter.Code.Tuple`** - Working with tuples

## When to Use Igniter for Module Installation

### Primary Use Cases

Igniter should be the **preferred method** for installing and configuring Elixir modules and dependencies that support it. Use Igniter whenever:

1. **Installing Ash Framework Extensions:**
   ```bash
   mix igniter.install ash_postgres
   mix igniter.install ash_authentication  
   mix igniter.install ash_ai
   mix igniter.install ash_phoenix
   ```

2. **Installing Phoenix Components:**
   ```bash
   mix igniter.install phoenix_live_view
   mix igniter.install phoenix_live_dashboard
   ```

3. **Installing Testing Libraries:**
   ```bash
   mix igniter.install wallaby
   mix igniter.install ex_machina
   ```

4. **Installing Development Tools:**
   ```bash
   mix igniter.install credo
   mix igniter.install dialyxir
   ```

### Benefits of Using Igniter

- **Automatic Configuration:** Igniter automatically updates config files, dependencies, and application configuration
- **Code Generation:** Creates boilerplate code with proper conventions and patterns
- **Safe Modifications:** Uses AST manipulation to make precise, conflict-free changes
- **Rollback Support:** Changes can be reviewed and reverted if needed
- **Consistency:** Ensures installations follow project conventions and patterns

### Installation Guidelines for Agents

When working on xPando, AI agents should:

1. **Always check for Igniter support first:** Before manually adding dependencies, check if the library supports Igniter installation
2. **Use Igniter for supported libraries:** If available, prefer `mix igniter.install` over manual `mix.exs` editing
3. **Review generated changes:** Always examine what Igniter generated before committing
4. **Follow up with testing:** Run tests after Igniter installations to verify integration

### Common Igniter Installation Patterns

```bash
# For Ash framework components (always use Igniter)
mix igniter.install ash_postgres
mix igniter.install ash_authentication
mix igniter.install ash_phoenix
mix igniter.install ash_ai

# For Phoenix ecosystem (preferred)
mix igniter.install phoenix_live_view
mix igniter.install phoenix_live_dashboard

# For development dependencies (when available)
mix igniter.install credo --dev
mix igniter.install dialyxir --dev

# For testing dependencies (when available) 
mix igniter.install wallaby --test
mix igniter.install ex_machina --test
```

### Manual Installation Fallback

Only use manual `mix.exs` dependency addition when:
- The library doesn't support Igniter
- Custom configuration is required that Igniter doesn't handle
- Integration with existing code requires manual intervention

### Agent Integration Rules

For AI agents working on xPando:

1. **Before adding ANY new Elixir dependency, check if it supports Igniter**
2. **If Igniter is supported, ALWAYS use `mix igniter.install` instead of manual dependency addition**
3. **After Igniter installation, run `mix deps.get` and `mix compile` to verify**
4. **Review all generated files and configurations before proceeding**
5. **Add Igniter installations to commit messages for transparency**
