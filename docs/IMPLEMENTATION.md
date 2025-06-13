# 📖 Implementation Guide - Cross-Domain Arbitrage Bot

## 🎯 Overview

This guide provides step-by-step instructions for implementing each component of the Cross-Domain Arbitrage Bot.

## 🚀 Phase 1: Smart Contracts (Week 1-2)

### 1.1 Core Contracts

```solidity
// contracts/src/core/BundleBuilder.sol - Main execution contract
contract BundleBuilder is Ownable, ReentrancyGuard, AutomationCompatible {
    IPlanStore public planStore;
    IEdgeOracle public edgeOracle;
    ICCIPRouter public ccipRouter;
    
    function executeArbitrage(uint256 planId) external nonReentrant {
        // 1. Load plan from storage
        // 2. Validate execution condition
        // 3. Execute origin swap
        // 4. Send CCIP message
        // 5. Submit SUAVE bundle
    }
}
```

### 1.2 Supporting Contracts

```solidity
// contracts/src/core/PlanStore.sol
contract PlanStore {
    mapping(uint256 => ArbPlan) private plans;
    
    function storePlan(bytes calldata signedPlan) external onlyFunctions {
        // Verify signature and store plan
    }
}

// contracts/src/core/EdgeOracle.sol  
contract EdgeOracle {
    function deltaEdge(address tokenA, address tokenB) external view returns (uint256) {
        // Calculate price spread using Data Streams
    }
}
```

### 1.3 Deployment Steps

```bash
# Setup Foundry environment
cd contracts
forge install

# Deploy to testnet
forge script script/Deploy.s.sol --rpc-url $ARBITRUM_TESTNET_RPC_URL --broadcast

# Verify contracts
forge verify-contract --chain arbitrum-sepolia <CONTRACT_ADDRESS> BundleBuilder
```

## 🤖 Phase 2: AI Agents (Week 2-3)

### 2.1 Watcher Agent

```python
# agents/watcher/pool_monitor.py
class PoolMonitor:
    async def monitor_pools(self):
        while True:
            for pool in self.pools:
                reserves = await self.get_pool_reserves(pool)
                if self.detect_opportunity(reserves):
                    await self.notify_planner(opportunity)
            await asyncio.sleep(5)
```

### 2.2 Planner Agent

```python
# agents/planner/route_optimizer.py
class RouteOptimizer:
    async def optimize_route(self, opportunity):
        # 1. Simulate on Tenderly forks
        # 2. Calculate gas costs
        # 3. Find optimal route
        # 4. Generate execution plan
        return optimized_plan
```

### 2.3 Risk Guard Agent

```python
# agents/risk_guard/risk_assessor.py
class RiskAssessor:
    async def assess_plan(self, plan):
        # 1. Check risk parameters
        # 2. Validate profitability
        # 3. Sign with KMS if approved
        return signed_plan
```

## 🔗 Phase 3: Chainlink Integration (Week 3-4)

### 3.1 Functions Setup

```javascript
// chainlink/functions/source.js
const source = `
const bedrockResponse = await Functions.makeHttpRequest({
    url: args[0], // Bedrock endpoint
    headers: { "Authorization": "Bearer " + secrets.apiKey }
});

// Verify KMS signature
const isValid = verifySignature(bedrockResponse.data);
if (!isValid) throw new Error("Invalid signature");

return Functions.encodeBytes32String(JSON.stringify(bedrockResponse.data));
`;
```

### 3.2 Automation Setup

```javascript
// chainlink/automation/register.js
const upkeepTx = await registry.registerUpkeep({
    name: "Arbitrage Bot",
    encryptedEmail: "0x",
    upkeepContract: bundleBuilderAddress,
    gasLimit: 500000,
    adminAddress: adminAddress,
    checkData: "0x",
    amount: ethers.utils.parseEther("10")
});
```

## 🌉 Phase 4: SUAVE Integration (Week 4)

### 4.1 Bundle Builder

```python
# suave/bundle_builder.py
class BundleBuilder:
    async def create_bundle(self, plan):
        bundle = {
            "version": "v0.1",
            "inclusion": {"block": "latest"},
            "body": [
                {"tx": self.build_arbitrage_tx(plan)},
                {"tx": self.build_ccip_tx(plan)}
            ]
        }
        return await self.submit_bundle(bundle)
```

## 📊 Phase 5: Monitoring (Week 4-5)

### 5.1 Dashboard

```python
# monitoring/dashboard/app.py
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

app = FastAPI()

@app.get("/api/status")
async def get_status():
    return {
        "agents_running": check_agents_health(),
        "contracts_deployed": check_contracts(),
        "recent_profits": get_recent_profits()
    }
```

## 🧪 Testing Strategy

### Unit Tests

```bash
# Smart contract tests
cd contracts && forge test

# Python agent tests  
pytest agents/tests/

# Integration tests
pytest tests/test_e2e.py
```

### Simulation Tests

```python
# Test with Tenderly forks
async def test_full_arbitrage():
    # 1. Setup fork with price difference
    # 2. Deploy contracts
    # 3. Execute arbitrage
    # 4. Verify profit realization
```

## 🚀 Deployment Guide

### Testnet Deployment

```bash
# 1. Deploy contracts
make deploy-contracts-testnet

# 2. Setup Chainlink services
make setup-chainlink-testnet

# 3. Deploy AI agents
make deploy-agents-testnet

# 4. Start monitoring
make start-dashboard
```

### Mainnet Deployment

```bash
# WARNING: Requires extensive testing
make deploy-mainnet
```

## 🔧 Configuration

### Environment Setup

```bash
# Copy and configure environment
cp .env.example .env

# Required variables:
# - PRIVATE_KEY
# - AWS_ACCESS_KEY_ID
# - CHAINLINK_SUBSCRIPTION_ID
# - SUAVE_PRIVATE_KEY
```

## 📚 Resources

- [Chainlink Documentation](https://docs.chain.link/)
- [SUAVE Documentation](https://suave-alpha.flashbots.net/)
- [Foundry Book](https://book.getfoundry.sh/)
- [AWS Bedrock Guide](https://docs.aws.amazon.com/bedrock/)

## ⚠️ Important Notes

1. **Always test on testnets first**
2. **Use small amounts initially**
3. **Monitor gas prices carefully**
4. **Have emergency stop mechanisms**
5. **Keep private keys secure** 