# xPando Development Makefile
# Convenient commands for development workflow

.PHONY: help setup quality quality-full ci-check test clean install hooks

# Default target
help:
	@echo "🚀 xPando Development Commands"
	@echo ""
	@echo "Setup:"
	@echo "  make install     Install dependencies and setup project"
	@echo "  make setup       Setup database and assets"
	@echo "  make hooks       Install Git hooks for quality control"
	@echo ""
	@echo "Quality Control:"
	@echo "  make quality     Run basic quality checks (format, credo, compile)"
	@echo "  make quality-full Run full quality suite (includes tests & audit)"
	@echo "  make ci-check    Run exact CI checks locally"
	@echo "  make format      Format all code"
	@echo ""
	@echo "Development:"
	@echo "  make test        Run all tests"
	@echo "  make server      Start Phoenix server"
	@echo "  make clean       Clean build artifacts"
	@echo ""

# Project setup
install:
	@echo "📦 Installing dependencies..."
	mix deps.get
	cd apps/xpando_web/assets && npm install

setup: install
	@echo "🏗️  Setting up project..."
	mix ecto.setup
	mix assets.setup

hooks:
	@echo "🔗 Git hooks already installed in .git/hooks/"
	@echo "   - pre-commit: Automatic formatting"
	@echo "   - pre-push: Comprehensive quality checks"

# Quality control
quality:
	@echo "✨ Running basic quality checks..."
	mix quality

quality-full:
	@echo "🔍 Running full quality suite..."
	mix quality.full

ci-check:
	@echo "🤖 Running CI checks locally..."
	mix ci.local

format:
	@echo "📝 Formatting code..."
	mix format

# Development
test:
	@echo "🧪 Running tests..."
	mix test

server:
	@echo "🌐 Starting Phoenix server..."
	mix phx.server

# Maintenance
clean:
	@echo "🧹 Cleaning build artifacts..."
	mix clean
	rm -rf _build deps

# Advanced quality checks
dialyzer:
	@echo "🔬 Running Dialyzer analysis..."
	mix dialyzer

security:
	@echo "🔐 Running security checks..."
	mix deps.audit
	mix sobelow

# Pre-push simulation
pre-push-check:
	@echo "🚀 Simulating pre-push checks..."
	@echo "This runs the same checks as the pre-push hook"
	mix format --check-formatted
	mix credo --strict  
	mix compile --warnings-as-errors
	mix test
	mix deps.audit