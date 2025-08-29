# XPando AI Manual Testing Guide

> **Purpose**: Comprehensive testing documentation for the XPando AI P2P distributed network
> 
> **What is XPando AI?** A decentralized P2P network where AI nodes share knowledge, validate contributions, and earn reputation/tokens.

## 📖 Table of Contents

### Getting Started
1. [Initial Setup & Prerequisites](01_setup.md) - Database setup, Phoenix server, IEx console
2. [Quick Start Test](02_quick_start.md) - Complete system test in one script

### Core Features
3. [User Management](03_user_management.md) - User creation, roles, authentication
4. [Node Registration & Management](04_node_management.md) - Node registration, cryptographic identity, specializations
5. [Knowledge Distribution](05_knowledge_distribution.md) - Knowledge creation, validation workflows, querying
6. [Contribution & Validation](06_contribution_validation.md) - Peer review, enhancements, validation scoring

### P2P Networking
7. [P2P Network Testing](07_p2p_network.md) - Network health, multi-node clusters, PubSub messaging

### Advanced Features
8. [Advanced Testing Scenarios](08_advanced_testing.md) - Reputation evolution, load testing, performance monitoring

### Utilities
9. [Troubleshooting & Utilities](09_troubleshooting.md) - Common issues, data cleanup, debugging tools

## 🚀 Quick Navigation

**New to XPando?** Start with:
1. [Initial Setup](01_setup.md) for prerequisites and configuration
2. [Quick Start Test](02_quick_start.md) to verify everything works
3. Then explore individual features in order (03-09)

**Testing specific features?** Jump directly to:
- [User System](03_user_management.md) for authentication and roles
- [Node Management](04_node_management.md) for P2P node operations
- [Knowledge System](05_knowledge_distribution.md) for content distribution
- [Network Testing](07_p2p_network.md) for P2P connectivity

**Having issues?** Check:
- [Troubleshooting](09_troubleshooting.md) for common problems and solutions

## 📝 Testing Workflow

1. **Setup** - Follow [Initial Setup](01_setup.md) guide
2. **Verify** - Run [Quick Start Test](02_quick_start.md)
3. **Explore** - Test individual features using numbered guides (03-08)
4. **Debug** - Use [Troubleshooting](09_troubleshooting.md) if needed

## 🏗️ System Architecture

```
XPando AI
├── Core (xpando_core)
│   ├── Users (authentication, roles)
│   ├── Nodes (P2P participants)
│   ├── Knowledge (distributed content)
│   ├── Contributions (validations)
│   └── Tokens (authentication tokens)
├── Web (xpando_web)
│   └── Phoenix web interface
└── Node (xpando_node)
    └── P2P networking layer
```

## 💡 Tips for Testing

- All test commands run in IEx console
- Use parentheses for pipelines after assignments: `var = (Module |> function())`
- Test in order: Users → Nodes → Knowledge → Contributions
- Clean test data between sessions using cleanup utilities

## 📚 Additional Resources

- Ash Framework docs: https://hexdocs.pm/ash
- Phoenix docs: https://hexdocs.pm/phoenix
- Source code: `apps/xpando_core/lib/xpando/core/`

---

**Happy Testing! 🚀** Select a guide above to begin testing XPando AI features.