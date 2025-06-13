# 🚀 Cross-Domain Arbitrage Bot - Hackathon Edition

> **2-Week Sprint**: Autonomous MEV searcher demonstrating cross-chain arbitrage between Arbitrum and Avalanche using Chainlink CCIP, Amazon Bedrock AI agents, and SUAVE Helios for MEV protection.

## 🎯 Hackathon Objectives

**Primary Goal**: Demonstrate a working cross-chain arbitrage flow in 2 weeks
- ✅ AI-powered opportunity detection (Amazon Bedrock)
- ✅ Atomic execution with MEV protection (SUAVE Helios)  
- ✅ Cross-chain bridging (Chainlink CCIP)
- ✅ Automated monitoring and execution (Chainlink Automation)

## 🏗️ Simplified Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   AI Watcher    │───▶│  Opportunity     │───▶│   Execution     │
│  (Bedrock)      │    │  Validator       │    │   Engine        │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                ▲                        │
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ Price Feeds     │───▶│  Chainlink       │◀───│   CCIP Bridge   │
│ (Data Streams)  │    │  Functions       │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                ▲                        │
                       ┌──────────────────┐    ┌─────────────────┐
                       │  Automation      │◀───│  SUAVE Helios   │
                       │  (Cron Jobs)     │    │  (MEV Shield)   │
                       └──────────────────┘    └─────────────────┘
```

## 🚀 Quick Start (15 minutes)

### Prerequisites
```bash
node --version    # v18+
python --version  # 3.9+
forge --version   # foundry
docker --version  # for local services
```

### 1. Clone & Setup
```bash
git clone <your-repo>
cd chainlink-arbitrage-bot
make install-all
```

### 2. Environment Setup
```bash
cp .env.example .env
# Edit .env with your keys (no KMS needed!)
make setup-local
```

### 3. Start Local Stack
```bash
make dev-start    # Starts all services
make test-flow    # Tests the full arbitrage flow
```

## 🛠️ Tech Stack (Simplified)

### Core Technologies
- **AI Layer**: Amazon Bedrock (Claude 3.5 Sonnet) - Simple prompt-based agents
- **Execution**: Chainlink Functions + Automation (no complex scheduling)
- **Pricing**: Chainlink Data Streams (basic price feeds)
- **Cross-Chain**: Chainlink CCIP (standard bridge operations)
- **MEV Protection**: SUAVE Helios (basic bundle submission)

### Development Stack
- **Contracts**: Foundry (Solidity 0.8.19)
- **Backend**: Python 3.9+ (web3py, boto3)
- **Frontend**: Simple React dashboard (optional)
- **Database**: SQLite (no PostgreSQL complexity)
- **Monitoring**: Basic logging (no Grafana/Prometheus)

## 📁 Project Structure

```
├── contracts/               # Solidity contracts
│   ├── src/
│   │   ├── BundleBuilder.sol       # Main execution contract
│   │   └── interfaces/             # Contract interfaces
│   └── test/                       # Contract tests
├── agents/                  # AI agents (simplified)
│   ├── watcher.py                  # Price monitoring
│   ├── planner.py                  # Strategy planning
│   └── executor.py                 # Trade execution
├── chainlink/              # Chainlink integrations
│   ├── functions/                  # Chainlink Functions
│   ├── automation/                 # Automation configs
│   └── ccip/                      # Cross-chain setup
├── config/                 # Configuration files
├── scripts/                # Deployment & utility scripts
├── tests/                  # Integration tests
└── monitoring/             # Basic monitoring setup
```

## 🎮 Usage Examples

### Manual Arbitrage Detection
```bash
# Monitor price differences
python agents/watcher.py --chains arbitrum,avalanche

# Execute detected opportunity
python agents/executor.py --opportunity-id 12345
```

### View Dashboard
```bash
make dashboard        # Opens local monitoring dashboard
```

## 🔧 Configuration

### Core Settings (.env)
```bash
# Blockchain RPCs (use public endpoints for hackathon)
ARBITRUM_RPC_URL=https://arb1.arbitrum.io/rpc
AVALANCHE_RPC_URL=https://api.avax.network/ext/bc/C/rpc

# AWS Bedrock (simplified auth)
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_REGION=us-east-1

# Chainlink Services
CHAINLINK_API_KEY=your_api_key
CHAINLINK_AUTOMATION_REGISTRY=0x...

# SUAVE (testnet)
SUAVE_RPC_URL=https://rpc.rigil.suave.flashbots.net
```

### Supported DEXs & Tokens
- **Arbitrum**: Uniswap V3, Camelot, Balancer
- **Avalanche**: Trader Joe, Pangolin, Curve
- **Tokens**: WETH, USDC, USDT, WBTC (top 4 for simplicity)

## 🧪 Testing

### Run Test Suite
```bash
make test-all           # Full test suite
make test-contracts     # Contract tests only
make test-agents        # AI agent tests
make test-integration   # End-to-end flow
```

### Simulate Arbitrage
```bash
make simulate-arb       # Simulates profitable arbitrage
```

## 📊 2-Week Milestones

### Week 1: Core Infrastructure
- **Days 1-3**: Smart contracts + basic AI agents
- **Days 4-5**: Chainlink Functions + Data Streams
- **Days 6-7**: CCIP integration + local testing

### Week 2: Integration & Demo
- **Days 8-10**: SUAVE integration + full flow testing
- **Days 11-12**: Monitoring dashboard + bug fixes
- **Days 13-14**: Demo preparation + documentation

## 🚨 Hackathon Limitations

### What's Simplified
- **Security**: Basic key management (no KMS/HSM)
- **Monitoring**: Console logging instead of full observability
- **Database**: SQLite instead of PostgreSQL
- **Deployment**: Local only (no cloud infrastructure)
- **Testing**: Core flows only (no edge case handling)

### What's Maintained
- **Core Flow**: Full arbitrage detection → execution → bridging
- **AI Integration**: Real Bedrock agents for opportunity detection
- **Chainlink Stack**: Functions, Automation, CCIP, Data Streams
- **MEV Protection**: SUAVE Helios bundle submission

## 🎯 Success Metrics

### Technical Demos
1. **AI Detection**: Show Bedrock agent finding price differences
2. **Atomic Execution**: Demonstrate bundle execution via SUAVE
3. **Cross-Chain Bridge**: Show CCIP transfer completion
4. **Profit Calculation**: Display net profit after gas costs

### Performance Targets
- **Detection Latency**: < 10 seconds
- **Execution Time**: < 3 minutes end-to-end
- **Minimum Profit**: > 0.1% after gas costs
- **Success Rate**: > 80% for detected opportunities

## 🤝 Team Roles (2 Developers)

### Developer 1: Smart Contracts + Chainlink
- BundleBuilder contract implementation
- Chainlink Functions + Automation setup
- CCIP cross-chain logic
- Contract testing

### Developer 2: AI Agents + SUAVE
- Bedrock agent development
- SUAVE Helios integration
- Price monitoring system
- Integration testing

## 📞 Support

### Resources
- [Chainlink Documentation](https://docs.chain.link/)
- [Amazon Bedrock Docs](https://docs.aws.amazon.com/bedrock/)
- [SUAVE Documentation](https://suave.flashbots.net/)

### Community
- Chainlink Discord: #hackathon-support
- SUAVE Telegram: @suave-dev
- Project Issues: GitHub Issues tab

---

**Built for Chainlink Hackathon 2024** | **Estimated Timeline: 14 days** | **Team Size: 2 developers**

