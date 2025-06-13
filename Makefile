# ============================================
# Cross-Domain Arbitrage Bot - Hackathon
# ============================================

.PHONY: help install test clean dev-start dev-stop

# Default target
help:
	@echo "🚀 Cross-Domain Arbitrage Bot - Hackathon Edition"
	@echo ""
	@echo "Quick Start Commands:"
	@echo "  make install-all     - Install all dependencies"
	@echo "  make setup-local     - Setup local environment"
	@echo "  make dev-start       - Start development environment"
	@echo "  make test-flow       - Test full arbitrage flow"
	@echo "  make dashboard       - Open monitoring dashboard"
	@echo ""
	@echo "Development Commands:"
	@echo "  make test-all        - Run all tests"
	@echo "  make test-contracts  - Test smart contracts"
	@echo "  make test-agents     - Test AI agents"
	@echo "  make clean           - Clean build artifacts"
	@echo ""
	@echo "Demo Commands:"
	@echo "  make simulate-arb    - Simulate arbitrage opportunity"
	@echo "  make demo-flow       - Run full demo flow"

# ============ INSTALLATION ============

install-all: install-node install-python install-foundry
	@echo "✅ All dependencies installed"

install-node:
	@echo "📦 Installing Node.js dependencies..."
	npm install

install-python:
	@echo "🐍 Installing Python dependencies..."
	pip install -r requirements.txt

install-foundry:
	@echo "⚒️ Installing Foundry dependencies..."
	cd contracts && forge install

# ============ ENVIRONMENT SETUP ============

setup-local:
	@echo "🔧 Setting up local environment..."
	@cp env.example .env || echo "⚠️ Please copy env.example to .env and fill in your values"
	@mkdir -p logs
	@mkdir -p data
	@echo "✅ Local environment setup complete"

# ============ DEVELOPMENT ============

dev-start:
	@echo "🚀 Starting development environment..."
	@echo "Starting local services in background..."
	@python -m agents.watcher &
	@echo "Started price watcher"
	@if [ "$(ENABLE_DASHBOARD)" = "true" ]; then \
		python -m monitoring.dashboard &\
		echo "Started dashboard on http://localhost:8080"; \
	fi
	@echo "✅ Development environment running"

dev-stop:
	@echo "🛑 Stopping development environment..."
	@pkill -f "python -m agents" || true
	@pkill -f "python -m monitoring" || true
	@echo "✅ Development environment stopped"

# ============ TESTING ============

test-all: test-contracts test-agents test-integration
	@echo "✅ All tests completed"

test-contracts:
	@echo "🧪 Testing smart contracts..."
	cd contracts && forge test -vv

test-agents:
	@echo "🤖 Testing AI agents..."
	python -m pytest tests/test_agents.py -v

test-integration:
	@echo "🔗 Testing integration..."
	python -m pytest tests/test_integration.py -v

test-flow:
	@echo "⚡ Testing full arbitrage flow..."
	python scripts/test_full_flow.py

# ============ CONTRACT OPERATIONS ============

compile:
	@echo "🔨 Compiling contracts..."
	cd contracts && forge build

deploy-testnet:
	@echo "🚀 Deploying to testnet..."
	cd contracts && forge script script/Deploy.s.sol --broadcast --verify --rpc-url $(ARBITRUM_RPC_URL)

# ============ DEMO & SIMULATION ============

simulate-arb:
	@echo "💰 Simulating arbitrage opportunity..."
	python scripts/simulate_arbitrage.py

demo-flow:
	@echo "🎯 Running full demo flow..."
	@echo "1. Starting price monitoring..."
	python -m agents.watcher --demo-mode &
	@sleep 5
	@echo "2. Triggering opportunity detection..."
	python scripts/trigger_opportunity.py
	@sleep 10
	@echo "3. Executing arbitrage..."
	python scripts/execute_demo.py
	@echo "✅ Demo flow completed"

# ============ MONITORING ============

dashboard:
	@echo "📊 Opening monitoring dashboard..."
	@if command -v open >/dev/null 2>&1; then \
		open http://localhost:8080; \
	elif command -v xdg-open >/dev/null 2>&1; then \
		xdg-open http://localhost:8080; \
	else \
		echo "📊 Dashboard available at http://localhost:8080"; \
	fi

logs:
	@echo "📋 Showing recent logs..."
	tail -f logs/arbitrage.log

# ============ UTILITIES ============

clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf contracts/out/
	@rm -rf contracts/cache/
	@rm -rf node_modules/.cache/
	@rm -rf __pycache__/
	@rm -rf *.pyc
	@find . -name "*.pyc" -delete
	@echo "✅ Clean completed"

format:
	@echo "✨ Formatting code..."
	cd contracts && forge fmt
	black agents/ scripts/ tests/
	@echo "✅ Code formatted"

check-env:
	@echo "🔍 Checking environment..."
	@python scripts/check_environment.py

# ============ QUICK COMMANDS ============

quick-test: compile test-contracts
	@echo "⚡ Quick test completed"

dev: dev-start dashboard
	@echo "🎯 Development environment ready!"

# ============ CHAINLINK SETUP ============

setup-chainlink:
	@echo "🔗 Setting up Chainlink services..."
	@echo "Creating Chainlink Functions subscription..."
	@echo "⚠️ Manual setup required - see README for details"

# ============ SUAVE SETUP ============

setup-suave:
	@echo "🛡️ Setting up SUAVE integration..."
	python scripts/setup_suave.py

# ============ STATUS & INFO ============

status:
	@echo "📈 System Status:"
	@echo "▶️ Checking services..."
	@pgrep -f "python -m agents" && echo "✅ Watcher running" || echo "❌ Watcher stopped"
	@curl -s http://localhost:8080/health > /dev/null && echo "✅ Dashboard running" || echo "❌ Dashboard stopped"
	@echo "▶️ Database status:"
	@test -f arbitrage_data.db && echo "✅ Database exists" || echo "❌ Database not found"

info:
	@echo "ℹ️ Project Information:"
	@echo "📁 Project: Cross-Domain Arbitrage Bot"
	@echo "🎯 Mode: Hackathon Edition (2-week sprint)"
	@echo "🔗 Chains: Arbitrum ↔ Avalanche"
	@echo "🤖 AI: Amazon Bedrock"
	@echo "⚡ Automation: Chainlink Services"
	@echo "🛡️ MEV Protection: SUAVE Helios" 