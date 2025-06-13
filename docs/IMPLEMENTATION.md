# 📖 Implementation Guide - Cross-Domain Arbitrage Bot (Hackathon Edition)

## 🎯 Overview

This guide provides step-by-step instructions for implementing the **simplified hackathon version** of the Cross-Domain Arbitrage Bot. Focus is on working functionality over production complexity.

## 🚀 Phase 1: Local Environment Setup (Day 1-2)

### 1.1 Prerequisites

```bash
# Required software
- Python 3.9+
- Node.js 18+
- Git
- AWS CLI (for Bedrock)

# Clone repository
git clone <repository-url>
cd cross-domain-arbitrage-bot

# Python environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# Node.js dependencies
npm install
```

### 1.2 Environment Configuration

```bash
# Copy and configure environment
cp env.example .env

# Fill in required values:
# - AWS credentials for Bedrock
# - RPC URLs (use public endpoints)
# - Private key for testnet deployment
```

### 1.3 Database Setup

```bash
# Initialize SQLite database
python -c "
from agents.watcher import SimplifiedWatcher
watcher = SimplifiedWatcher()
watcher.init_database()
print('Database initialized successfully!')
"
```

## 🤖 Phase 2: AI Agents Implementation (Day 3-5)

### 2.1 Watcher Agent Testing

```bash
# Test price monitoring
python agents/watcher.py

# Expected output:
# 🔍 Starting price monitoring...
# 📊 Monitoring 4 DEX pools across 2 chains
# 💾 Storing price data to SQLite
```

### 2.2 Planner Agent with Bedrock

```python
# Test AI planning functionality
from agents.planner import ArbitragePlanner
import asyncio

async def test_planner():
    planner = ArbitragePlanner()
    
    # Mock opportunity
    opportunity = {
        'token': 'WETH',
        'chain_a': 'arbitrum',
        'chain_b': 'avalanche', 
        'price_a': 2485.0,
        'price_b': 2510.0,
        'spread_bps': 100,
        'profit_estimate': 25.0
    }
    
    plan = await planner.process_opportunity(opportunity)
    print(f"Plan generated: {plan['plan_id']}")
    print(f"Expected profit: ${plan['expected_profit']:.2f}")

# Run test
asyncio.run(test_planner())
```

### 2.3 Executor Agent

```python
# Test execution coordination
from agents.executor import ArbitrageExecutor
import asyncio

async def test_executor():
    executor = ArbitrageExecutor()
    stats = await executor.get_execution_stats()
    print(f"Execution stats: {stats}")

asyncio.run(test_executor())
```

## 🔗 Phase 3: Chainlink Integration (Day 6-8)

### 3.1 Functions Deployment

```bash
# Navigate to Functions directory
cd chainlink/functions

# Install Functions toolkit
npm install @chainlink/functions-toolkit

# Deploy Functions consumer
npx hardhat deploy --network arbitrumSepolia

# Register Functions subscription
node scripts/register-subscription.js
```

### 3.2 Functions Source Deployment

```javascript
// Deploy the source code
const { SubscriptionManager } = require("@chainlink/functions-toolkit");

async function deploySource() {
    const subscriptionId = process.env.FUNCTIONS_SUBSCRIPTION_ID;
    const source = require('./source.js').source;
    
    const manager = new SubscriptionManager({
        signer: wallet,
        linkTokenAddress: process.env.LINK_TOKEN_ADDRESS,
        functionsRouterAddress: process.env.FUNCTIONS_ROUTER_ADDRESS
    });
    
    const requestTx = await manager.requestExecution({
        source: source,
        subscriptionId: subscriptionId,
        args: [],
        gasLimit: 300000
    });
    
    console.log(`Functions request sent: ${requestTx.hash}`);
}

deploySource().catch(console.error);
```

### 3.3 Automation Setup

```bash
# Register Chainlink Automation upkeep
cd chainlink/automation
node upkeep.js register

# Monitor upkeep status
node upkeep.js monitor <UPKEEP_ID>
```

## 🌉 Phase 4: Smart Contracts (Day 9-10)

### 4.1 Contract Compilation

```bash
cd contracts
forge build

# Expected output:
# [⠊] Compiling...
# [⠊] Installing solc version 0.8.19
# [⠢] Successfully installed solc 0.8.19
# Compiler run successful!
```

### 4.2 Testnet Deployment

```bash
# Deploy to Arbitrum Sepolia
forge script script/Deploy.s.sol \
    --rpc-url $ARBITRUM_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify

# Deploy to Avalanche Fuji
forge script script/Deploy.s.sol \
    --rpc-url $AVALANCHE_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify
```

### 4.3 Contract Verification

```bash
# Verify BundleBuilder contract
forge verify-contract \
    --chain arbitrum-sepolia \
    <CONTRACT_ADDRESS> \
    src/BundleBuilder.sol:BundleBuilder \
    --etherscan-api-key $ETHERSCAN_API_KEY
```

## 🛡️ Phase 5: SUAVE Integration (Day 11-12)

### 5.1 SUAVE Setup

```python
# Test SUAVE bundle creation
from suave.bundle_builder import SUAVEBundleBuilder
import asyncio

async def test_suave():
    builder = SUAVEBundleBuilder()
    
    # Mock plan for testing
    test_plan = {
        'plan_id': 'ARB_TEST_12345',
        'token': 'WETH',
        'trade_size_usd': 10000,
        'trade_size_tokens': 4.0,
        'expected_profit': 150.0,
        'profit_bps': 150,
        'buy_chain': 'arbitrum',
        'sell_chain': 'avalanche'
    }
    
    bundle_id = await builder.create_arbitrage_bundle(test_plan)
    print(f"SUAVE bundle created: {bundle_id}")

asyncio.run(test_suave())
```

### 5.2 Bundle Submission Testing

```python
# Test bundle status monitoring
async def monitor_bundle():
    builder = SUAVEBundleBuilder()
    status = await builder.get_bundle_status("test_bundle_123")
    print(f"Bundle status: {status}")
    
    success_rate = await builder.estimate_bundle_success_rate(test_plan)
    print(f"Success rate: {success_rate:.1%}")

asyncio.run(monitor_bundle())
```

## 📊 Phase 6: Monitoring Dashboard (Day 13)

### 6.1 Dashboard Launch

```bash
# Start monitoring dashboard
python monitoring/dashboard.py

# Expected output:
# 🚀 Starting Arbitrage Dashboard...
# 📊 Dashboard: http://localhost:8080
# INFO:     Started server process
# INFO:     Uvicorn running on http://0.0.0.0:8080
```

### 6.2 Dashboard Features

- **Real-time Metrics**: Opportunities, executions, profits
- **Active Plans**: Current approved plans awaiting execution
- **Execution History**: Recent transaction records
- **Performance Stats**: Success rates and profitability

### 6.3 API Endpoints

```bash
# Test API endpoints
curl http://localhost:8080/api/data
curl http://localhost:8080/api/approved-plans

# Expected: JSON response with dashboard data
```

## 🧪 Phase 7: Integration Testing (Day 14)

### 7.1 Full Flow Test

```bash
# Run comprehensive end-to-end test
python scripts/test_full_flow.py

# Expected output:
# 🚀 Starting Full Arbitrage Flow Test
# 📁 Setting up test databases...
# 🔍 Simulating opportunity detection...
# 🧠 Testing plan generation...
# 🛡️ Testing SUAVE integration...
# ⚡ Testing execution flow...
# ✅ Full Flow Test Completed Successfully!
```

### 7.2 Unit Tests

```bash
# Run agent tests
pytest tests/test_agents.py -v

# Expected output:
# tests/test_agents.py::TestSimplifiedWatcher::test_database_initialization PASSED
# tests/test_agents.py::TestSimplifiedWatcher::test_price_storage PASSED
# tests/test_agents.py::TestArbitragePlanner::test_optimal_size_calculation PASSED
# ========================= X passed in Y.YYs =========================
```

### 7.3 Performance Testing

```python
# Test system performance
import time
import asyncio
from agents.watcher import SimplifiedWatcher

async def performance_test():
    watcher = SimplifiedWatcher()
    
    start_time = time.time()
    
    # Simulate 100 price updates
    for i in range(100):
        watcher.store_price('arbitrum', 'uniswap_v3', 'WETH', 2500 + i)
    
    end_time = time.time()
    print(f"100 price updates took: {end_time - start_time:.2f} seconds")

asyncio.run(performance_test())
```

## 🚀 Phase 8: Demo Preparation (Day 14)

### 8.1 Demo Script

```python
# Create demo data for presentation
from agents.watcher import SimplifiedWatcher
import time

def create_demo_data():
    watcher = SimplifiedWatcher()
    
    # Create realistic arbitrage opportunity
    watcher.store_price('arbitrum', 'uniswap_v3', 'WETH', 2485.50)
    watcher.store_price('avalanche', 'trader_joe', 'WETH', 2510.25)
    
    print("Demo data created!")
    print("WETH Arbitrum: $2,485.50")
    print("WETH Avalanche: $2,510.25") 
    print("Spread: ~99 basis points")
    print("Expected profit: ~$25 per WETH")

create_demo_data()
```

### 8.2 Demo Flow

1. **Start Dashboard**: `python monitoring/dashboard.py`
2. **Show Live Data**: Navigate to `http://localhost:8080`
3. **Trigger Opportunity**: Run demo data script
4. **Show AI Planning**: Display Bedrock integration
5. **Show Execution**: Demonstrate SUAVE bundle creation
6. **Show Results**: Real-time dashboard updates

### 8.3 Key Demo Points

- **AI Decision Making**: Amazon Bedrock validates plans
- **Chainlink Integration**: Functions and Automation working
- **MEV Protection**: SUAVE bundle submission
- **Cross-Chain**: CCIP message flow simulation
- **Real-Time Monitoring**: Live dashboard with metrics

## 🛠️ Troubleshooting

### Common Issues

1. **Bedrock Access Denied**
   ```bash
   # Ensure AWS credentials are configured
   aws configure
   aws bedrock list-foundation-models --region us-east-1
   ```

2. **Database Locked Error**
   ```bash
   # Remove SQLite lock file
   rm arbitrage_data.db-journal
   ```

3. **RPC Rate Limiting**
   ```bash
   # Use rate-limited requests in code
   await asyncio.sleep(0.1)  # Add delays between requests
   ```

4. **SUAVE Connection Issues**
   ```python
   # Check SUAVE testnet status
   import requests
   response = requests.get("https://rpc.rigil.suave.flashbots.net")
   print(f"SUAVE status: {response.status_code}")
   ```

### Debug Commands

```bash
# Check agent status
python -c "from agents.watcher import SimplifiedWatcher; w = SimplifiedWatcher(); print('Watcher OK')"

# Verify database
sqlite3 arbitrage_data.db ".tables"

# Test network connectivity
curl -X POST https://arb1.arbitrum.io/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

## 📈 Success Metrics

### Demo Success Criteria

- ✅ **Opportunity Detection**: Watcher finds price discrepancies
- ✅ **AI Validation**: Bedrock approves profitable plans  
- ✅ **Plan Storage**: SQLite stores approved plans
- ✅ **Dashboard Display**: Real-time monitoring works
- ✅ **SUAVE Integration**: Bundle creation succeeds
- ✅ **Flow Completion**: End-to-end test passes

### Performance Targets

- **Opportunity Detection**: < 10 seconds
- **AI Plan Generation**: < 5 seconds
- **Dashboard Response**: < 2 seconds
- **Database Operations**: < 1 second
- **Full Flow Time**: < 2 minutes

This implementation guide ensures rapid development while demonstrating all key technologies: Amazon Bedrock AI, Chainlink services, and SUAVE MEV protection in a working cross-chain arbitrage system. 