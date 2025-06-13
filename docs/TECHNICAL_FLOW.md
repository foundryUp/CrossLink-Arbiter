# 🔧 Technical Flow: Bedrock → Functions → Automation

## Overview

This document explains the exact technical connection between Amazon Bedrock, Chainlink Functions, and Chainlink Automation in our Cross-Domain Arbitrage Bot.

## 🧠 Step 1: Amazon Bedrock (Off-Chain AI Detection)

### Watcher Agent - Price Monitoring
```python
# agents/watcher/pool_monitor.py
class PoolMonitor:
    async def monitor_pools(self):
        while True:
            # Get prices from Arbitrum DEXs
            arb_price = await self.get_price("arbitrum", "WETH/USDC")
            
            # Get prices from Avalanche DEXs  
            avax_price = await self.get_price("avalanche", "WETH/USDC")
            
            # Calculate price difference
            price_diff = abs(arb_price - avax_price) / min(arb_price, avax_price)
            
            if price_diff > 0.005:  # 50 basis points threshold
                opportunity = ArbitrageOpportunity(
                    token_pair="WETH/USDC",
                    chain_a="arbitrum",
                    chain_b="avalanche", 
                    price_a=arb_price,
                    price_b=avax_price,
                    profit_bps=int(price_diff * 10000)
                )
                await self.send_to_planner(opportunity)
```

### Planner Agent - Strategy Optimization
```python
# agents/planner/strategy_planner.py
class StrategyPlanner:
    async def process_opportunity(self, opportunity):
        # Use Bedrock Claude for optimal sizing
        bedrock_response = await self.bedrock_client.invoke_model(
            modelId="anthropic.claude-3-sonnet-20240229-v1:0",
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "messages": [{
                    "role": "user", 
                    "content": f"Calculate optimal trade size for arbitrage: {opportunity}"
                }]
            })
        )
        
        plan = ArbitragePlan(
            opportunity_id=opportunity.id,
            trade_size=bedrock_response.optimal_size,
            expected_profit=bedrock_response.expected_profit,
            gas_estimate=bedrock_response.gas_cost,
            execution_deadline=time.time() + 300  # 5 minute window
        )
        
        await self.send_to_risk_guard(plan)
```

### Risk Guard - Validation
```python
# agents/risk_guard/validator.py  
class RiskValidator:
    async def validate_plan(self, plan):
        # Multi-layer validation
        risk_score = await self.calculate_risk_score(plan)
        
        if (risk_score < 0.3 and 
            plan.expected_profit > plan.gas_estimate * 1.5 and
            plan.trade_size < self.max_position_size):
            
            # Approve plan and make available via API
            await self.store_approved_plan(plan)
            await self.notify_chainlink_functions()
        else:
            await self.reject_plan(plan, reason="Risk too high")
```

### Bedrock API Endpoint
```python
# api/bedrock_bridge.py
@app.get("/api/approved-plans") 
async def get_approved_plans():
    """
    Chainlink Functions calls this endpoint to fetch approved arbitrage plans
    """
    plans = await db.get_pending_approved_plans()
    
    if not plans:
        return {"status": "no_plans", "data": None}
        
    # Return the highest profit plan
    best_plan = max(plans, key=lambda p: p.expected_profit)
    
    return {
        "status": "plan_available",
        "data": {
            "plan_id": best_plan.id,
            "token_pair": best_plan.token_pair,
            "source_chain": best_plan.source_chain,
            "dest_chain": best_plan.dest_chain,
            "trade_size": str(best_plan.trade_size),
            "expected_profit": str(best_plan.expected_profit),
            "execution_deadline": best_plan.execution_deadline,
            "source_dex": best_plan.source_dex,
            "dest_dex": best_plan.dest_dex
        }
    }
```

## 🌐 Step 2: Chainlink Functions (Plan Ingress)

### Functions Source Code
```javascript
// chainlink/functions/source.js
const source = `
// This code runs in Chainlink's decentralized compute environment

// 1. Fetch approved plan from Bedrock API
const bedrockResponse = await Functions.makeHttpRequest({
    url: "https://your-bedrock-api.com/api/approved-plans",
    method: "GET",
    headers: {
        "Authorization": "Bearer " + secrets.apiKey
    }
});

if (bedrockResponse.error) {
    throw Error("Failed to fetch plan from Bedrock API");
}

const planData = bedrockResponse.data;

// 2. Validate plan data structure
if (!planData.data || planData.status !== "plan_available") {
    return Functions.encodeString(JSON.stringify({
        success: false,
        reason: "No approved plans available"
    }));
}

const plan = planData.data;

// 3. Validate execution deadline
const currentTime = Math.floor(Date.now() / 1000);
if (currentTime > plan.execution_deadline) {
    return Functions.encodeString(JSON.stringify({
        success: false, 
        reason: "Plan expired"
    }));
}

// 4. Return validated plan for on-chain storage
return Functions.encodeString(JSON.stringify({
    success: true,
    plan: {
        planId: plan.plan_id,
        tokenPair: plan.token_pair,
        sourceChain: plan.source_chain,
        destChain: plan.dest_chain,
        tradeSize: plan.trade_size,
        expectedProfit: plan.expected_profit,
        executionDeadline: plan.execution_deadline,
        sourceDex: plan.source_dex,
        destDex: plan.dest_dex
    }
}));
`;
```

### Functions Consumer Contract
```solidity
// contracts/src/PlanIngress.sol
contract PlanIngress is FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;
    
    IPlanStore public planStore;
    bytes32 public donId;
    
    event PlanIngressRequested(bytes32 indexed requestId);
    event PlanStored(uint256 indexed planId, string tokenPair);
    
    function requestPlanFromBedrock() external {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        req.addSecretsReference(encryptedSecretsUrls);
        
        bytes32 requestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donId
        );
        
        emit PlanIngressRequested(requestId);
    }
    
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (err.length > 0) {
            // Handle error
            return;
        }
        
        // Decode response from Bedrock
        string memory responseString = string(response);
        
        // Parse JSON response (simplified)
        // In practice, use a JSON parsing library
        if (keccak256(bytes(responseString)) != keccak256(bytes("no_plans"))) {
            // Store plan in PlanStore contract
            uint256 planId = planStore.storePlan(responseString);
            emit PlanStored(planId, "WETH/USDC");
        }
    }
}
```

### Plan Storage Contract
```solidity
// contracts/src/PlanStore.sol
contract PlanStore {
    struct ArbitragePlan {
        uint256 id;
        string tokenPair;
        uint256 sourceChain;
        uint256 destChain;
        uint256 tradeSize;
        uint256 expectedProfit;
        uint256 executionDeadline;
        string sourceDex;
        string destDex;
        bool executed;
        uint256 timestamp;
    }
    
    mapping(uint256 => ArbitragePlan) public plans;
    uint256 public latestPlanId;
    
    event PlanStored(uint256 indexed planId, string tokenPair);
    
    function storePlan(string memory planData) external returns (uint256) {
        // Parse plan data and create ArbitragePlan struct
        // Simplified for demonstration
        
        latestPlanId++;
        plans[latestPlanId] = ArbitragePlan({
            id: latestPlanId,
            tokenPair: "WETH/USDC", // parsed from planData
            sourceChain: 42161,     // Arbitrum
            destChain: 43114,       // Avalanche
            tradeSize: 1000000000000000000, // 1 WETH
            expectedProfit: 10000000, // 10 USDC
            executionDeadline: block.timestamp + 300,
            sourceDex: "UniswapV3",
            destDex: "TraderJoe", 
            executed: false,
            timestamp: block.timestamp
        });
        
        emit PlanStored(latestPlanId, "WETH/USDC");
        return latestPlanId;
    }
    
    function getLatestPlan() external view returns (ArbitragePlan memory) {
        return plans[latestPlanId];
    }
}
```

## ⚙️ Step 3: Chainlink Automation (Execution Trigger)

### Upkeep Contract
```solidity
// contracts/src/ArbitrageUpkeep.sol
contract ArbitrageUpkeep is AutomationCompatibleInterface {
    IPlanStore public planStore;
    IBundleBuilder public bundleBuilder;
    
    uint256 public lastExecutedPlanId;
    
    // This function is called by Chainlink Automation to check if upkeep is needed
    function checkUpkeep(bytes calldata checkData) 
        external 
        view 
        override 
        returns (bool upkeepNeeded, bytes memory performData) 
    {
        IPlanStore.ArbitragePlan memory plan = planStore.getLatestPlan();
        
        // Check if there's a new plan to execute
        bool newPlan = plan.id > lastExecutedPlanId;
        
        // Check if plan hasn't expired
        bool notExpired = block.timestamp <= plan.executionDeadline;
        
        // Check if plan hasn't been executed
        bool notExecuted = !plan.executed;
        
        // Additional market condition checks could go here
        bool marketConditionsGood = checkMarketConditions(plan);
        
        upkeepNeeded = newPlan && notExpired && notExecuted && marketConditionsGood;
        
        if (upkeepNeeded) {
            performData = abi.encode(plan.id);
        }
    }
    
    // This function is called by Chainlink Automation when conditions are met
    function performUpkeep(bytes calldata performData) external override {
        uint256 planId = abi.decode(performData, (uint256));
        
        // Verify conditions are still met (security check)  
        IPlanStore.ArbitragePlan memory plan = planStore.plans(planId);
        require(block.timestamp <= plan.executionDeadline, "Plan expired");
        require(!plan.executed, "Plan already executed");
        require(planId > lastExecutedPlanId, "Plan already processed");
        
        // Execute the arbitrage via BundleBuilder
        bundleBuilder.executeArbitrage(planId);
        
        // Update tracking
        lastExecutedPlanId = planId;
        
        emit ArbitrageExecuted(planId, plan.tokenPair);
    }
    
    function checkMarketConditions(IPlanStore.ArbitragePlan memory plan) 
        internal 
        view 
        returns (bool) 
    {
        // Could integrate with Chainlink Data Streams here
        // For now, simple gas price check
        return tx.gasprice <= 100 gwei;
    }
    
    event ArbitrageExecuted(uint256 indexed planId, string tokenPair);
}
```

## 🔄 Complete Flow Example

### Real Execution Sequence

1. **T=0**: Watcher detects WETH price difference
   - Arbitrum: 2,485 USDC per WETH
   - Avalanche: 2,510 USDC per WETH  
   - Difference: 1.006% (100.6 basis points)

2. **T=0.5s**: Planner calculates strategy
   - Optimal size: 15 WETH
   - Expected profit: 355 USDC
   - Gas estimate: 45 USDC

3. **T=1s**: Risk Guard validates
   - Net profit: 310 USDC (86.8 bps)
   - Risk score: 0.12 (low)
   - **Plan approved ✅**

4. **T=1.5s**: Chainlink Functions triggers
   - HTTP request to Bedrock API
   - Fetches approved plan
   - Stores in PlanStore contract

5. **T=2s**: Plan stored on-chain
   - PlanStore.storePlan() called
   - Plan ID: 1337
   - Execution deadline: T+300s

6. **T=2.5s**: Chainlink Automation checks
   - checkUpkeep() returns true
   - Conditions met: ✅ New plan, ✅ Not expired, ✅ Good market conditions

7. **T=3s**: Execution triggered
   - performUpkeep() called with planId=1337
   - BundleBuilder.executeArbitrage(1337) invoked

8. **T=3-180s**: Cross-chain execution
   - CCIP message sent to Avalanche
   - Trades executed on both chains
   - Profit realized: 310 USDC

## 🔗 Integration Points

### API Integration
- **Bedrock → Functions**: HTTP API endpoint
- **Functions → On-chain**: Contract storage
- **Automation → Execution**: Contract calls

### Data Flow
- **Off-chain**: Python agents → PostgreSQL → REST API
- **On-chain**: Functions → PlanStore → Automation → BundleBuilder

### Error Handling
- **API timeouts**: Functions retry logic
- **Plan expiry**: Automation deadline checks  
- **Execution failures**: Revert handling and alerts

This architecture ensures reliable, automated arbitrage execution while maintaining decentralization and MEV protection. 



