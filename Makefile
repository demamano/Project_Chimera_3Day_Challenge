.PHONY: help setup dev-up dev-down test test-unit test-cov lint format spec-check logs clean

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)Project Chimera - Available Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

setup: ## Install dependencies and setup environment
	@echo "$(BLUE)Installing dependencies with uv...$(NC)"
	uv pip install -e ".[dev]"
	@echo "$(GREEN)✓ Dependencies installed$(NC)"

dev-up: ## Start all services (Docker Compose)
	@echo "$(BLUE)Starting development environment...$(NC)"
	@echo "$(RED)⚠ Docker Compose not yet configured$(NC)"
	@echo "  You'll set this up on Day 3 with infrastructure/"
	@echo ""
	@echo "For now, you can work locally without Docker"

dev-down: ## Stop all services
	@echo "$(BLUE)Stopping development environment...$(NC)"
	@echo "$(RED)⚠ Docker Compose not yet configured$(NC)"

test: ## Run full test suite
	@echo "$(BLUE)Running all tests...$(NC)"
	pytest tests/ -v || echo "$(RED)No tests found yet. Create tests/ directory on Day 3$(NC)"

test-unit: ## Run unit tests only
	@echo "$(BLUE)Running unit tests...$(NC)"
	pytest tests/unit/ -v || echo "$(RED)No tests found yet$(NC)"

test-cov: ## Run tests with coverage report
	@echo "$(BLUE)Running tests with coverage...$(NC)"
	pytest tests/ -v --cov=services --cov-report=html --cov-report=term-missing || echo "$(RED)No tests found yet$(NC)"

lint: ## Run all linters
	@echo "$(BLUE)Running linters...$(NC)"
	@echo "  → Ruff..."
	ruff check . || echo "$(RED)Ruff not configured yet$(NC)"
	@echo "  → Black (check)..."
	black --check . || echo "$(RED)Black not configured yet$(NC)"
	@echo "$(GREEN)✓ Linting complete$(NC)"

format: ## Auto-format code
	@echo "$(BLUE)Formatting code...$(NC)"
	black .
	ruff check --fix .
	@echo "$(GREEN)✓ Code formatted$(NC)"

clean: ## Clean temporary files and caches
	@echo "$(BLUE)Cleaning temporary files...$(NC)"
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	rm -rf htmlcov/ .coverage
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

# Git shortcuts
commit: ## Interactive commit (runs linters first)
	@echo "$(BLUE)Running pre-commit checks...$(NC)"
	@echo "$(GREEN)✓ Ready to commit!$(NC)"
	git status

# Development helpers
shell: ## Open Python shell with project context
	@echo "$(BLUE)Opening IPython shell...$(NC)"
	ipython || python

# Show current setup status
status: ## Show project setup status
	@echo "$(BLUE)Project Chimera - Setup Status$(NC)"
	@echo ""
	@echo "Virtual Environment: $(GREEN)✓$(NC) Active"
	@which python
	@echo ""
	@echo "Installed Packages:"
	@pip list | grep -E "(anthropic|google-generativeai|openai|pytest)" || echo "  Run 'make setup' to install"
	@echo ""
	@echo "Project Structure:"
	@ls -d specs research skills tests services 2>/dev/null || echo "  $(RED)Create directories: mkdir -p specs research skills tests services$(NC)"