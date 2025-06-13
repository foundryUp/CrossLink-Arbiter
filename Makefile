# Cross-Domain Arbitrage Bot Makefile
# =================================

# Default target
.DEFAULT_GOAL := help

# Variables
NETWORK ?= testnet
VERBOSE ?= false

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Help command
help: ## Show this help message
	@echo "$(BLUE)Cross-Domain Arbitrage Bot - Available Commands$(NC)"
	@echo "================================================"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Setup and Installation
# ======================

install: ## Install all dependencies
	@echo "$(YELLOW)Installing dependencies...$(NC)"
	npm install
	pip install -r requirements.txt
	cd contracts && forge install

setup: install ## Setup development environment
	@echo "$(YELLOW)Setting up development environment...$(NC)"
	cp .env.example .env
	mkdir -p logs
	docker-compose up -d postgres redis
	python scripts/setup_env.py

clean: ## Clean build artifacts and dependencies
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	rm -rf node_modules dist coverage .nyc_output
	rm -rf contracts/out contracts/cache
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete

# Development
# ===========

dev: ## Start development environment
	@echo "$(YELLOW)Starting development environment...$(NC)"
	docker-compose up -d
	npm run dev &
	python -m agents.main &
	python -m monitoring.dashboard.app

test: ## Run all tests
	@echo "$(YELLOW)Running tests...$(NC)"
	cd contracts && forge test
	npm test
	pytest tests/

test-coverage: ## Run tests with coverage
	@echo "$(YELLOW)Running tests with coverage...$(NC)"
	cd contracts && forge coverage
	npm run test:coverage
	pytest tests/ --cov=agents --cov-report=html

lint: ## Run linters
	@echo "$(YELLOW)Running linters...$(NC)"
	npm run lint
	cd contracts && forge fmt --check
	black agents/ --check
	flake8 agents/

lint-fix: ## Fix linting issues
	@echo "$(YELLOW)Fixing linting issues...$(NC)"
	npm run lint:fix
	cd contracts && forge fmt
	black agents/
	isort agents/

# Smart Contracts
# ===============

compile: ## Compile smart contracts
	@echo "$(YELLOW)Compiling smart contracts...$(NC)"
	cd contracts && forge build

deploy-contracts-testnet: compile ## Deploy contracts to testnet
	@echo "$(YELLOW)Deploying contracts to testnet...$(NC)"
	cd contracts && forge script script/Deploy.s.sol --rpc-url $(ARBITRUM_TESTNET_RPC_URL) --broadcast --verify

deploy-contracts-mainnet: compile ## Deploy contracts to mainnet
	@echo "$(RED)Deploying contracts to mainnet...$(NC)"
	@echo "$(RED)WARNING: This will deploy to mainnet. Are you sure? [y/N]$(NC)"
	@read -r CONTINUE; \
	if [ "$$CONTINUE" = "y" ] || [ "$$CONTINUE" = "Y" ]; then \
		cd contracts && forge script script/Deploy.s.sol --rpc-url $(ARBITRUM_RPC_URL) --broadcast --verify; \
	else \
		echo "$(YELLOW)Deployment cancelled.$(NC)"; \
	fi

verify-contracts: ## Verify contracts on block explorer
	@echo "$(YELLOW)Verifying contracts...$(NC)"
	cd contracts && forge script script/Verify.s.sol

# Chainlink Services
# ==================

setup-chainlink-testnet: ## Setup Chainlink services on testnet
	@echo "$(YELLOW)Setting up Chainlink services on testnet...$(NC)"
	node chainlink/functions/deploy.js --network testnet
	node chainlink/automation/register.js --network testnet

setup-chainlink-mainnet: ## Setup Chainlink services on mainnet
	@echo "$(RED)Setting up Chainlink services on mainnet...$(NC)"
	node chainlink/functions/deploy.js --network mainnet
	node chainlink/automation/register.js --network mainnet

# AI Agents
# =========

deploy-agents-testnet: ## Deploy AI agents to AWS (testnet)
	@echo "$(YELLOW)Deploying AI agents to AWS (testnet)...$(NC)"
	python scripts/deploy_agents.py --env testnet

deploy-agents-mainnet: ## Deploy AI agents to AWS (mainnet)
	@echo "$(RED)Deploying AI agents to AWS (mainnet)...$(NC)"
	python scripts/deploy_agents.py --env mainnet

start-agents: ## Start AI agents locally
	@echo "$(YELLOW)Starting AI agents locally...$(NC)"
	python -m agents.main

stop-agents: ## Stop AI agents
	@echo "$(YELLOW)Stopping AI agents...$(NC)"
	pkill -f "python -m agents.main"

# Full Deployment
# ===============

deploy-testnet: ## Full deployment to testnet
	@echo "$(YELLOW)Full deployment to testnet...$(NC)"
	$(MAKE) deploy-contracts-testnet
	$(MAKE) setup-chainlink-testnet
	$(MAKE) deploy-agents-testnet

deploy-mainnet: ## Full deployment to mainnet
	@echo "$(RED)Full deployment to mainnet...$(NC)"
	$(MAKE) deploy-contracts-mainnet
	$(MAKE) setup-chainlink-mainnet
	$(MAKE) deploy-agents-mainnet

# Monitoring and Utilities
# ========================

start-dashboard: ## Start monitoring dashboard
	@echo "$(YELLOW)Starting monitoring dashboard...$(NC)"
	python -m monitoring.dashboard.app

status: ## Check system status
	@echo "$(YELLOW)Checking system status...$(NC)"
	python -m monitoring.cli.status

profits: ## Show profit history
	@echo "$(YELLOW)Showing profit history...$(NC)"
	python -m monitoring.cli.profits --days 7

gas-tracker: ## Monitor gas prices
	@echo "$(YELLOW)Monitoring gas prices...$(NC)"
	python tools/gas_tracker.py

# Database
# ========

db-migrate: ## Run database migrations
	@echo "$(YELLOW)Running database migrations...$(NC)"
	python scripts/migrate.py

db-reset: ## Reset database
	@echo "$(YELLOW)Resetting database...$(NC)"
	docker-compose down postgres
	docker-compose up -d postgres
	sleep 5
	python scripts/migrate.py

# Docker
# ======

docker-build: ## Build Docker images
	@echo "$(YELLOW)Building Docker images...$(NC)"
	docker-compose build

docker-up: ## Start Docker services
	@echo "$(YELLOW)Starting Docker services...$(NC)"
	docker-compose up -d

docker-down: ## Stop Docker services
	@echo "$(YELLOW)Stopping Docker services...$(NC)"
	docker-compose down

docker-logs: ## Show Docker logs
	@echo "$(YELLOW)Showing Docker logs...$(NC)"
	docker-compose logs -f

# Security
# ========

audit-contracts: ## Audit smart contracts
	@echo "$(YELLOW)Auditing smart contracts...$(NC)"
	cd contracts && slither src/

security-check: ## Run security checks
	@echo "$(YELLOW)Running security checks...$(NC)"
	npm audit
	safety check
	bandit -r agents/

# Utilities
# =========

format: ## Format all code
	@echo "$(YELLOW)Formatting code...$(NC)"
	npm run format
	cd contracts && forge fmt
	black agents/
	isort agents/

docs: ## Generate documentation
	@echo "$(YELLOW)Generating documentation...$(NC)"
	cd contracts && forge doc
	sphinx-build -b html docs/ docs/_build/

backup: ## Backup configuration and data
	@echo "$(YELLOW)Creating backup...$(NC)"
	tar -czf backup-$(shell date +%Y%m%d-%H%M%S).tar.gz config/ logs/ .env

.PHONY: help install setup clean dev test test-coverage lint lint-fix compile deploy-contracts-testnet deploy-contracts-mainnet verify-contracts setup-chainlink-testnet setup-chainlink-mainnet deploy-agents-testnet deploy-agents-mainnet start-agents stop-agents deploy-testnet deploy-mainnet start-dashboard status profits gas-tracker db-migrate db-reset docker-build docker-up docker-down docker-logs audit-contracts security-check format docs backup 