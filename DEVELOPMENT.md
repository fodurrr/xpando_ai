# Development Workflow & Quality Control

This document outlines the automated quality control measures in place to prevent CI failures and maintain code quality.

## 🛡️ Automated Quality Control

### Git Hooks (Automatic)

**Pre-Commit Hook** (`.git/hooks/pre-commit`)
- ✅ **Auto-formats** code before each commit
- ✅ **Prevents** commits with unformatted code
- ⚡ **Fast** - runs in seconds

**Pre-Push Hook** (`.git/hooks/pre-push`)  
- ✅ **Comprehensive checks** before pushing to main/master
- ✅ **Prevents CI failures** by running the same checks locally
- 🔍 Includes: compile, format check, Credo, tests, security audit

### Quick Commands

```bash
# Basic quality checks (recommended before commits)
mix quality
make quality

# Full quality suite (recommended before push)
mix quality.full  
make quality-full

# Test exact CI conditions locally
mix ci.local
make ci-check

# Setup everything
make install && make setup
```

## 🔧 Available Mix Aliases

```bash
mix quality           # format + credo + compile
mix quality.full      # format + credo + compile + test + audit  
mix ci.local         # Same checks as CI (strict)
mix ci.prepare       # deps.get + format + credo + compile
```

## 🎯 Quality Standards Enforced

1. **Code Formatting** - All code auto-formatted with `mix format`
2. **Static Analysis** - Credo strict mode with zero warnings
3. **Compilation** - Zero warnings in production builds
4. **Documentation** - All modules must have `@moduledoc`
5. **Type Safety** - Dialyzer analysis (when enabled)
6. **Security** - Dependency audit checks

## 🚨 Troubleshooting

### "Pre-commit checks failed"
```bash
# Auto-fix formatting issues
mix format
git add .
git commit --amend --no-edit
```

### "Pre-push checks failed"  
```bash
# Run checks individually to identify issues
mix format --check-formatted  # Fix: mix format
mix credo --strict           # Fix: Address Credo suggestions
mix compile --warnings-as-errors  # Fix: Address compiler warnings
mix test                     # Fix: Fix failing tests
```

### Bypassing Hooks (Emergency Only)
```bash
# Skip pre-commit (not recommended)
git commit --no-verify

# Skip pre-push (not recommended)  
git push --no-verify
```

## 💡 IDE Integration

### VS Code
- Install recommended extensions (auto-prompted)
- Auto-format on save enabled
- Credo integration for real-time feedback

### Other Editors
- Set up format-on-save with `mix format`
- Configure to run `mix quality` before commits

## 🔄 Workflow Recommendations

### Daily Development
1. Code normally
2. Hooks handle quality automatically
3. Use `make quality` when unsure

### Before Major Push
1. Run `make quality-full`
2. Review all changes
3. Push with confidence

### Emergency Fixes
1. Use `make ci-check` to verify
2. Test locally first
3. Monitor CI after push

## 📊 Quality Metrics Tracked

- Code formatting compliance: 100%
- Static analysis warnings: 0
- Test coverage: Tracked in CI
- Security vulnerabilities: 0 high/critical
- Documentation coverage: All public modules

This setup ensures that quality issues are caught and fixed locally before they reach CI, saving time and maintaining high code quality standards.
EOF < /dev/null