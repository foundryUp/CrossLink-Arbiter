# Cross-Domain Arbitrage Bot Project Structure (Hackathon Edition)

## 📁 Simplified Structure

```
chainlink-arbitrage-bot/
├── README.md                          # Main project overview and setup
├── .env.example                       # Environment variables template
├── .gitignore                         # Git ignore file
├── package.json                       # Node.js dependencies
├── requirements.txt                   # Python dependencies
├── docker-compose.yml                 # Docker setup for development
├── Makefile                          # Build and deployment commands
├── PROJECT_SUMMARY.md                # Project summary and overview
├── TEAM_TASKS.md                     # Team task breakdown (2-week sprint)
├── project-structure.md              # This file
│
├── contracts/                        # Solidity smart contracts (simplified)
│   ├── foundry.toml                  # Foundry configuration
│   ├── src/
│   │   ├── BundleBuilder.sol         # Main execution contract
│   │   └── IBundleBuilder.sol        # Contract interface
│   ├── test/
│   │   └── BundleBuilder.t.sol       # Basic contract tests
│   ├── script/
│   │   └── Deploy.s.sol              # Deployment script
│   └── lib/                          # Foundry dependencies
│
├── agents/                           # AI agents (single files)
│   ├── watcher.py                    # Price monitoring & opportunity detection
│   ├── planner.py                    # Amazon Bedrock AI planning
│   └── executor.py                   # Execution coordination
│
├── chainlink/                        # Chainlink integrations
│   ├── functions/
│   │   ├── source.js                 # Functions source code
│   │   └── config.json               # Functions configuration
│   └── automation/
│       └── upkeep.js                 # Automation setup and monitoring
│
├── suave/                            # SUAVE Helios integration
│   ├── bundle_builder.py             # Bundle creation and submission
│   └── SUAVE_GUIDE.md               # Complete SUAVE beginner's guide
│
├── monitoring/                       # Monitoring (simplified)
│   └── dashboard.py                  # Single-file FastAPI dashboard
│
├── scripts/                          # Utility scripts
│   ├── test_full_flow.py             # End-to-end testing
│   └── setup.py                      # Environment setup
│
├── tests/                            # Tests
│   └── test_agents.py                # Agent unit tests
│
├── docs/                             # Documentation (updated for hackathon)
│   ├── ARCHITECTURE.md               # Simplified architecture
│   ├── IMPLEMENTATION.md             # Hackathon implementation guide
│   ├── TEAM_TASKS.md                 # 2-week team tasks
│   ├── practical-example.md          # Demo flow example
│   └── diagrams/                     # Architecture diagrams
│
├── config/                           # Configuration
│   ├── chains.json                   # Chain configurations
│   └── tokens.json                   # Token configurations
│
└── tools/                            # Development tools (minimal)
    └── debug.py                      # Debugging utilities
```

## 🎯 Hackathon Simplifications

### What We Removed
- ❌ Complex agent subdirectories (watcher/, planner/, risk_guard/)
- ❌ Multiple monitoring components (metrics/, cli/, alerts/)
- ❌ KMS integration and complex security
- ❌ PostgreSQL and Redis dependencies
- ❌ Multiple environment configs
- ❌ Complex testing infrastructure

### What We Kept
- ✅ Core arbitrage functionality
- ✅ AI integration (Amazon Bedrock)
- ✅ Chainlink services (Functions, Automation, CCIP)
- ✅ SUAVE MEV protection
- ✅ Real-time dashboard
- ✅ End-to-end testing
- ✅ Complete documentation

## 📄 Key Files Explained

### Core Implementation
| File | Purpose | Lines | Complexity |
|------|---------|-------|------------|
| `agents/watcher.py` | Price monitoring & SQLite storage | ~200 | Simple |
| `agents/planner.py` | Amazon Bedrock AI integration | ~150 | Medium |
| `agents/executor.py` | Execution coordination | ~100 | Simple |
| `monitoring/dashboard.py` | Real-time web dashboard | ~300 | Medium |
| `contracts/src/BundleBuilder.sol` | Smart contract execution | ~200 | Medium |

### Integrations
| File | Purpose | Technology | Status |
|------|---------|------------|--------|
| `chainlink/functions/source.js` | AI plan fetching | Chainlink Functions | ✅ Working |
| `chainlink/automation/upkeep.js` | Automated execution | Chainlink Automation | ✅ Working |
| `suave/bundle_builder.py` | MEV protection | SUAVE Helios | ✅ Working |
| `scripts/test_full_flow.py` | E2E testing | Python asyncio | ✅ Working |

### Documentation
| File | Purpose | Audience |
|------|---------|----------|
| `README.md` | Quick start guide | Developers |
| `docs/ARCHITECTURE.md` | System design | Technical review |
| `docs/IMPLEMENTATION.md` | Step-by-step guide | Development team |
| `docs/practical-example.md` | Demo walkthrough | Presentation |
| `suave/SUAVE_GUIDE.md` | SUAVE integration | SUAVE beginners |

## 🗄️ Database Schema (SQLite)

```sql
-- arbitrage_data.db
CREATE TABLE price_data (
    id INTEGER PRIMARY KEY,
    chain TEXT NOT NULL,
    dex TEXT NOT NULL,
    token_pair TEXT NOT NULL,
    price REAL NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE opportunities (
    id INTEGER PRIMARY KEY,
    token TEXT NOT NULL,
    chain_a TEXT NOT NULL,
    chain_b TEXT NOT NULL,
    price_a REAL NOT NULL,
    price_b REAL NOT NULL,
    spread_bps INTEGER NOT NULL,
    profit_estimate REAL NOT NULL,
    status TEXT DEFAULT 'detected',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE arbitrage_plans (
    plan_id TEXT PRIMARY KEY,
    token TEXT NOT NULL,
    trade_size_usd REAL NOT NULL,
    expected_profit REAL NOT NULL,
    status TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE executions (
    id INTEGER PRIMARY KEY,
    plan_id TEXT NOT NULL,
    tx_hash TEXT,
    expected_profit REAL NOT NULL,
    actual_profit REAL,
    status TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## 🔧 Configuration Files

### Environment Variables (`.env`)
```bash
# AWS Bedrock
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1

# Blockchain RPCs
ARBITRUM_RPC_URL=https://arb1.arbitrum.io/rpc
AVALANCHE_RPC_URL=https://api.avax.network/ext/bc/C/rpc

# Chainlink
CHAINLINK_FUNCTIONS_SUBSCRIPTION_ID=123
LINK_TOKEN_ADDRESS=0x...
FUNCTIONS_ROUTER_ADDRESS=0x...

# SUAVE
SUAVE_RPC_URL=https://rpc.rigil.suave.flashbots.net
SUAVE_PRIVATE_KEY=0x...

# Application
ENVIRONMENT=hackathon
DEBUG=true
LOG_LEVEL=INFO
```

### Chain Configuration (`config/chains.json`)
```json
{
  "arbitrum": {
    "chainId": 42161,
    "rpcUrl": "https://arb1.arbitrum.io/rpc",
    "dexes": ["uniswap_v3", "camelot"],
    "ccipChainSelector": "4949039107694359620"
  },
  "avalanche": {
    "chainId": 43114,
    "rpcUrl": "https://api.avax.network/ext/bc/C/rpc", 
    "dexes": ["trader_joe", "pangolin"],
    "ccipChainSelector": "6433500567565415381"
  }
}
```

## 🚀 Development Workflow

### 1. Local Setup
```bash
git clone <repository>
cd chainlink-arbitrage-bot
make install-all     # Install all dependencies
make setup-local     # Setup local environment
```

### 2. Development Cycle
```bash
# Start agents
python agents/watcher.py &
python agents/planner.py &

# Start dashboard
python monitoring/dashboard.py &

# Run tests
python scripts/test_full_flow.py
```

### 3. Deployment
```bash
# Deploy contracts
cd contracts && forge script script/Deploy.s.sol --broadcast

# Configure Chainlink services
cd chainlink && node automation/upkeep.js register
```

## 📊 File Sizes & Complexity

### Small Files (< 100 lines)
- `agents/executor.py` - Simple coordination logic
- `config/*.json` - Configuration files
- `scripts/setup.py` - Environment setup

### Medium Files (100-300 lines)
- `agents/watcher.py` - Price monitoring with SQLite
- `agents/planner.py` - Bedrock AI integration
- `monitoring/dashboard.py` - FastAPI web server
- `contracts/src/BundleBuilder.sol` - Smart contract

### Large Files (300+ lines)
- `scripts/test_full_flow.py` - Comprehensive E2E testing
- `suave/SUAVE_GUIDE.md` - Complete SUAVE documentation

## 🎯 Hackathon Success Metrics

### Code Quality
- **Total Lines**: ~2,000 (vs 10,000+ in production version)
- **Files**: ~20 core files (vs 50+ in complex version)  
- **Dependencies**: Minimal (Web3, FastAPI, Boto3, Asyncio)
- **Setup Time**: < 15 minutes

### Functionality
- ✅ **AI Decision Making**: Amazon Bedrock integration
- ✅ **Cross-chain Arbitrage**: Arbitrum ↔ Avalanche
- ✅ **MEV Protection**: SUAVE bundle submission
- ✅ **Real-time Monitoring**: Live dashboard
- ✅ **Automated Execution**: Chainlink Automation
- ✅ **End-to-end Testing**: Complete flow validation

This simplified structure enables rapid development while maintaining all core functionalities for an impressive hackathon demonstration! 🚀 