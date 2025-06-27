# 🚀 **CrossLink Arbitor - Complete Deployment Guide**

This comprehensive guide covers everything you need to deploy, fund, and test your own CrossLink Arbitor system.

---

## 🎯 **Prerequisites**

### **Development Environment**
- Node.js 18+ and npm
- Foundry (forge, cast, anvil)
- Git for version control

### **Accounts & Access**
- **Private Key**: With testnet ETH on both Sepolia networks
- **AWS Account**: For Amazon Bedrock access
- **Alchemy Account**: For reliable RPC endpoints
- **Render Account**: For API hosting (optional)

### **Required Tokens**
- **Ethereum Sepolia**: ETH for gas, LINK for Chainlink services
- **Arbitrum Sepolia**: ETH for gas
- **Testnet Faucets**: Access to CCIP-BnM and WETH faucets

---

## 📦 **Step 1: Repository Setup**

### **1.1 Clone Repository**
```bash
git clone <repository-url>
cd crosslink-arbitor
npm install
cd ccip-starter && forge install
```

### **1.1.1 Create Environment File (Optional)**
For easier management, create a `.env` file in your project root:
```bash
# Create .env file with your values
cat > .env << 'EOF'
PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE
ETHEREUM_SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY_HERE
ARBITRUM_SEPOLIA_RPC_URL=https://arb-sepolia.g.alchemy.com/v2/YOUR_API_KEY_HERE
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY
AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_KEY
EOF

# Load environment variables
source .env
```

### **1.2 Environment Configuration**

#### **Initial Setup (Before Deployment)**
```bash
# Core environment variables (REPLACE WITH YOUR VALUES)
export PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE
export ETHEREUM_SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY_HERE
export ARBITRUM_SEPOLIA_RPC_URL=https://arb-sepolia.g.alchemy.com/v2/YOUR_API_KEY_HERE

# AWS Configuration (for Bedrock AI)
export AWS_REGION=us-east-1
export AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_KEY

# Token addresses (Ethereum Sepolia - these are fixed testnet addresses)
export WETH_ADDRESS=0xe95595f0BE77d6CF079795Ed63942933E9a6bf7b
export CCIP_BNM_ADDRESS=0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05
export LINK_ADDRESS=0x779877A7B0D9E8603169DdbD7836e478b4624789

# Token addresses (Arbitrum Sepolia - these are fixed testnet addresses)  
export ARB_WETH_ADDRESS=0x21ADF7b3F3AeA141E0b8544bF9de7e1e0CA21578
export ARB_CCIP_BNM_ADDRESS=0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D
```

#### **Post-Deployment Variables (Set After Contract Deployment)**
```bash
# Contract addresses (REPLACE WITH YOUR DEPLOYED ADDRESSES)
export PLAN_STORE_ADDRESS=<your_deployed_plan_store_address>
export BUNDLE_EXECUTOR_ADDRESS=<your_deployed_bundle_executor_address>
export FUNCTIONS_CONSUMER_ADDRESS=<your_deployed_functions_consumer_address>
export REMOTE_EXECUTOR_ADDRESS=<your_deployed_remote_executor_address>

# Pool addresses (REPLACE WITH YOUR DEPLOYED POOL ADDRESSES)
export ETH_POOL_ADDRESS=<your_ethereum_pool_address>
export ARB_POOL_ADDRESS=<your_arbitrum_pool_address>

# Chainlink service IDs (SET AFTER REGISTRATION)
export FUNCTIONS_SUBSCRIPTION_ID=<your_functions_subscription_id>
export FUNCTIONS_AUTOMATION_ID=<your_functions_consumer_upkeep_id>
export EXECUTOR_AUTOMATION_ID=<your_bundle_executor_upkeep_id>
```

---

## 🏗️ **Step 2: Smart Contract Deployment**

### **2.1 Deploy Ethereum Sepolia Contracts**
```bash
# Deploy main contracts
forge script script/DeployEthereumContracts.s.sol \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL \
  --broadcast --verify
```

### **2.1.1 Deploy Functions Consumer**

#### **Update Deploy Script with PlanStore Address & Subscription ID**
Before deploying the Functions Consumer, update both the PlanStore address and subscription ID:

```bash
# Edit the deploy script to include your PlanStore address
# Open script/DeployArbitrageFunctionsConsumer.s.sol and update the PLAN_STORE address
# Replace the placeholder with your deployed PlanStore address from step 2.1
```

**Manual Edits Required**:
1. **Update PlanStore Address**: Open `script/DeployArbitrageFunctionsConsumer.s.sol` and update the `PLAN_STORE` address variable with your deployed PlanStore address from the previous step.

2. **Hardcode Subscription ID**: Open `src/ArbitrageFunctionsConsumer.sol` and update the subscription ID:
   - Find the line with `_sendRequest(req.encodeCBOR(), 5125, gasLimit, donID)`
   - Replace `5125` with your actual Chainlink Functions subscription ID
   - Get your subscription ID from [functions.chain.link](https://functions.chain.link/) after creating your subscription

```solidity
// In ArbitrageFunctionsConsumer.sol, update this line:
s_lastRequestId = _sendRequest(
    req.encodeCBOR(),
    YOUR_SUBSCRIPTION_ID_HERE,  // Replace 5125 with your actual subscription ID
    gasLimit,
    donID
);
```

#### **Deploy Functions Consumer**
```bash
# Deploy ArbitrageFunctionsConsumer separately (after updating the script)
forge script script/DeployArbitrageFunctionsConsumer.s.sol \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL \
  --broadcast --verify

# Save the deployed addresses (note them for your environment variables)

# Set Functions Consumer in PlanStore
cast send --private-key $PRIVATE_KEY $PLAN_STORE_ADDRESS \
  "setFunctionsConsumer(address)" $FUNCTIONS_CONSUMER_ADDRESS \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Verify Functions Consumer is set correctly
cast call $PLAN_STORE_ADDRESS "functionsConsumer()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
# Should return: Your Functions Consumer address
```

### **2.2 Deploy Arbitrum Sepolia Contracts**
```bash
# Deploy remote executor
forge script script/DeployArbitrumContracts.s.sol \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL \
  --broadcast --verify

```

### **2.3 Resolve Circular Dependencies**
```bash
# Make sure your contract addresses are set in environment variables
# (Use the addresses from your deployment output)

# Configure BundleExecutor -> RemoteExecutor
forge script script/SetCircularAddresses.s.sol:SetCircularAddresses \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL --broadcast

# Configure RemoteExecutor -> BundleExecutor
forge script script/SetCircularAddresses.s.sol:SetAuthorizedSender \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast
```

### **2.4 Verify Contract Integration**
```bash
# Verify BundleExecutor knows RemoteExecutor
cast call $BUNDLE_EXECUTOR_ADDRESS "remoteExecutor()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
# Should return: RemoteExecutor address

# Verify RemoteExecutor knows BundleExecutor  
cast call $REMOTE_EXECUTOR_ADDRESS "authorizedSender()" --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
# Should return: BundleExecutor address

# Verify setter flags
cast call $BUNDLE_EXECUTOR_ADDRESS "remoteExecutorSet()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast call $REMOTE_EXECUTOR_ADDRESS "authorizedSenderSet()" --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
# Both should return: true
```

---

## 💰 **Step 3: Contract Funding**

### **3.1 Required Funding Summary**

#### **BundleExecutor (Ethereum Sepolia)**
- ✅ **ETH**: 0.003 ETH (for gas costs) 
- ✅ **WETH**: 10 WETH total (for sustained trading operations)
- ✅ **LINK**: 5 LINK total (for CCIP and Functions fees)
- 💡 **CCIP-BnM**: Variable (from faucet as needed)

#### **RemoteExecutor (Arbitrum Sepolia)**
- ✅ **ETH**: 0.005 ETH (for gas costs)
- 💡 **WETH**: Not needed initially (received via arbitrage)
- 💡 **CCIP-BnM**: Not needed initially (received via CCIP)

### **3.2 Initial Contract Funding**

#### **Fund BundleExecutor (Ethereum Sepolia)**
```bash
# Send ETH for gas costs
cast send --value 0.003ether $BUNDLE_EXECUTOR_ADDRESS \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Mint WETH for trading (10 WETH)
cast send $WETH_ADDRESS "mint(address,uint256)" \
  $BUNDLE_EXECUTOR_ADDRESS 10000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Transfer LINK for fees (5 LINK)
cast send $LINK_ADDRESS "transfer(address,uint256)" \
  $BUNDLE_EXECUTOR_ADDRESS 5000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

#### **Fund RemoteExecutor (Arbitrum Sepolia)**
```bash
# Send ETH for gas costs
cast send --value 0.005ether $REMOTE_EXECUTOR_ADDRESS \
  --private-key $PRIVATE_KEY \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

### **3.3 Emergency/Additional Funding Commands**

#### **Additional WETH (when needed)**
```bash
# Add more WETH for extended trading (5 WETH increments)
cast send $WETH_ADDRESS "mint(address,uint256)" \
  $BUNDLE_EXECUTOR_ADDRESS 5000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

#### **Additional LINK (when needed)**
```bash
# Add more LINK for extended operations (2 LINK increments)
cast send $LINK_ADDRESS "transfer(address,uint256)" \
  $BUNDLE_EXECUTOR_ADDRESS 2000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

#### **Get CCIP-BnM from Faucets**
```bash
# Ethereum Sepolia CCIP-BnM
cast send $CCIP_BNM_ADDRESS "drip(address)" \
  $BUNDLE_EXECUTOR_ADDRESS \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Arbitrum Sepolia CCIP-BnM
cast send $ARB_CCIP_BNM_ADDRESS "drip(address)" \
  $REMOTE_EXECUTOR_ADDRESS \
  --private-key $PRIVATE_KEY \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

---

## 🌊 **Step 4: Liquidity Pool Setup**

### **4.1 Deploy Liquidity Pools**
```bash
# Setup Ethereum Sepolia liquidity
forge script script/SetupLiquidity.s.sol \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL \
  --broadcast \
  --private-key $PRIVATE_KEY

# Setup Arbitrum Sepolia liquidity
# First set Arbitrum token addresses
export WETH_ADDRESS=$ARB_WETH_ADDRESS
export CCIP_BNM_ADDRESS=$ARB_CCIP_BNM_ADDRESS

forge script script/SetupLiquidity.s.sol \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL \
  --broadcast \
  --private-key $PRIVATE_KEY

# Reset to Ethereum addresses
export WETH_ADDRESS=0xe95595f0BE77d6CF079795Ed63942933E9a6bf7b
export CCIP_BNM_ADDRESS=0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05
```

### **4.2 Verify Pool Deployment**
```bash
# Use your deployed pool addresses (set these in your environment variables)

# Check Ethereum pool reserves
cast call $ETH_POOL_ADDRESS "getReserves()" \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Check Arbitrum pool reserves  
cast call $ARB_POOL_ADDRESS "getReserves()" \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

---

## 🌐 **Step 5: API Server Deployment**

### **5.1 Local Development**
```bash
cd chainlink-functions
npm install
node server.js

# Test API locally (use your deployed pool addresses)
curl "http://localhost:3000/api/analyze?ethPair=$ETH_POOL_ADDRESS&arbPair=$ARB_POOL_ADDRESS"
```

### **5.2 Production Deployment (Render.com)**
1. **Connect Repository**: Link your GitHub repo to Render
2. **Configure Build**: 
   - Build Command: `cd chainlink-functions && npm install`
   - Start Command: `cd chainlink-functions && node server.js`
3. **Environment Variables**: Add AWS credentials and other configs
4. **Deploy**: Render will auto-deploy and provide public URL

### **5.3 Verify API Deployment**
```bash
# Test production API (replace with your API URL and pool addresses)
curl "https://your-api-url.onrender.com/api/analyze?ethPair=$ETH_POOL_ADDRESS&arbPair=$ARB_POOL_ADDRESS"

# Expected response: CSV format with execute,amount,minEdgeBps,maxGasGwei
```

---

## 🔗 **Step 6: Chainlink Services Registration**

### **6.1 Chainlink Functions Setup**

#### **Create Subscription (REQUIRED BEFORE STEP 2.1.1)**
**⚠️ Important**: Create your Functions subscription BEFORE deploying the Functions Consumer (you need the subscription ID for deployment):

1. Visit [Chainlink Functions](https://functions.chain.link/)
2. Connect wallet and create new subscription
3. **Note your subscription ID** - you'll need this for hardcoding in the contract
4. Fund with minimum 5 LINK (for sustained operations)

#### **Update Consumer in Chainlink Interface**
After deploying your Functions Consumer:
1. Go to your Functions subscription on [functions.chain.link](https://functions.chain.link/)
2. Add your deployed `FUNCTIONS_CONSUMER_ADDRESS` as an authorized consumer
3. Verify the subscription is properly funded


### **6.2 Chainlink Automation Setup**

You need to register **TWO separate automations**:

#### **Automation 1: Functions Consumer (Time-Based) - Market Analysis**

##### **Register Time-Based Upkeep**
1. Visit [Chainlink Automation](https://automation.chain.link/)
2. Click "Register new Upkeep"
3. Select **"Time-based"** trigger
4. Configure upkeep:
   - **Target Contract**: Your ArbitrageFunctionsConsumer address
   - **Admin Address**: Your wallet address
   - **Function to Call**: `sendRequest()`
   - **Cron Schedule**: `0 */5 * * * *` (every 5 minutes)
   - **Gas Limit**: `300,000`
   - **Starting Balance**: 2 LINK minimum
   - **Upkeep Name**: "CrossLink Functions - Market Analysis"



#### **Automation 2: Bundle Executor (Custom Logic) - Arbitrage Execution**

##### **Register Custom Logic Upkeep**
1. Click "Register new Upkeep" (second upkeep)
2. Select **"Custom logic"** trigger
3. Configure upkeep:
   - **Target Contract**: Your BundleExecutor address
   - **Admin Address**: Your wallet address
   - **Check Data**: `0x` (empty)
   - **Gas Limit**: `500,000`
   - **Starting Balance**: 2 LINK minimum
   - **Upkeep Name**: "CrossLink Arbitor - Execution"

#### **Fund Both Upkeeps**
- Add LINK tokens to both upkeeps (2 LINK each minimum)
- Set up email notifications for low balance
- Monitor execution history for both automations

#### **Expected Automation Flow**
1. **Every 5 minutes**: Functions Consumer calls API → stores plan
2. **Every 15 seconds(Roughly)**: Bundle Executor checks for valid plans → executes if profitable

---

## 🧪 **Step 7: Manual Testing & Verification**

### **7.1 Complete Balance Check**
```bash
echo "=== ETHEREUM SEPOLIA BALANCES ==="
echo "BundleExecutor ETH: $(cast balance $BUNDLE_EXECUTOR_ADDRESS --rpc-url $ETHEREUM_SEPOLIA_RPC_URL)"
echo "BundleExecutor WETH: $(cast call $WETH_ADDRESS "balanceOf(address)" $BUNDLE_EXECUTOR_ADDRESS --rpc-url $ETHEREUM_SEPOLIA_RPC_URL)"
echo "BundleExecutor LINK: $(cast call $LINK_ADDRESS "balanceOf(address)" $BUNDLE_EXECUTOR_ADDRESS --rpc-url $ETHEREUM_SEPOLIA_RPC_URL)"
echo "BundleExecutor CCIP-BnM: $(cast call $CCIP_BNM_ADDRESS "balanceOf(address)" $BUNDLE_EXECUTOR_ADDRESS --rpc-url $ETHEREUM_SEPOLIA_RPC_URL)"

echo "=== ARBITRUM SEPOLIA BALANCES ==="
echo "RemoteExecutor ETH: $(cast balance $REMOTE_EXECUTOR_ADDRESS --rpc-url $ARBITRUM_SEPOLIA_RPC_URL)"
echo "RemoteExecutor WETH: $(cast call $ARB_WETH_ADDRESS "balanceOf(address)" $REMOTE_EXECUTOR_ADDRESS --rpc-url $ARBITRUM_SEPOLIA_RPC_URL)"
echo "RemoteExecutor CCIP-BnM: $(cast call $ARB_CCIP_BNM_ADDRESS "balanceOf(address)" $REMOTE_EXECUTOR_ADDRESS --rpc-url $ARBITRUM_SEPOLIA_RPC_URL)"
```

### **7.2 Test Manual Execution**

#### **Store Test Plan (Quick Test)**
```bash
# Store test plan via Functions Consumer
cast send $FUNCTIONS_CONSUMER_ADDRESS "storeTestPlan()" \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Check if plan was stored (within 5 minutes!)
cast call $PLAN_STORE_ADDRESS "shouldExecute()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
# Should return: true

# Get full plan details
cast call $PLAN_STORE_ADDRESS "getCurrentPlan()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
# Returns: (execute, amount, minEdgeBps, maxGasGwei, timestamp)
```

#### **Test Automation Conditions**
```bash
# Check if upkeep is needed
cast call $BUNDLE_EXECUTOR_ADDRESS "checkUpkeep(bytes)" 0x --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
# Should return: (true, 0x)

# If false, debug individual conditions:
echo "1. Remote Executor Set:"
cast call $BUNDLE_EXECUTOR_ADDRESS "remoteExecutorSet()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

echo "2. Plan Should Execute:"
cast call $PLAN_STORE_ADDRESS "shouldExecute()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

echo "3. Gas Price Check:"
cast gas-price --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast call $BUNDLE_EXECUTOR_ADDRESS "maxGasPrice()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

echo "4. WETH Balance Check:"
cast call $WETH_ADDRESS "balanceOf(address)" $BUNDLE_EXECUTOR_ADDRESS --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

#### **Manual Execution (for testing)**
```bash
# Execute manually if upkeep needed
cast send $BUNDLE_EXECUTOR_ADDRESS "performUpkeep(bytes)" 0x \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --gas-limit 500000
```

### **7.3 Quick Testing Workflow**
```bash
# IMPORTANT: Plans expire after 5 minutes!
# Run these commands in quick succession:

# Step 1: Store plan
cast send $FUNCTIONS_CONSUMER_ADDRESS "storeTestPlan()" \
  --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Step 2: Immediately check conditions (within 30 seconds)
cast call $PLAN_STORE_ADDRESS "shouldExecute()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast call $BUNDLE_EXECUTOR_ADDRESS "checkUpkeep(bytes)" 0x --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Step 3: Execute immediately if conditions are met
cast send $BUNDLE_EXECUTOR_ADDRESS "performUpkeep(bytes)" 0x \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --gas-limit 500000
```

---

## 📊 **Step 8: Monitoring & Maintenance**

### **8.1 System Health Checks**
```bash
# Check contract balances regularly
cast balance $BUNDLE_EXECUTOR_ADDRESS --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast call $WETH_ADDRESS "balanceOf(address)" $BUNDLE_EXECUTOR_ADDRESS --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast call $LINK_ADDRESS "balanceOf(address)" $BUNDLE_EXECUTOR_ADDRESS --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Monitor automation execution
# Check both upkeeps on automation.chain.link for execution history:
# 1. Functions Consumer (time-based) - should run every 5 minutes
# 2. Bundle Executor (custom logic) - should trigger when conditions are met

# Track CCIP messages
# Use ccip.chain.link to monitor cross-chain transfers
```

### **8.2 Emergency Funding Commands**
```bash
# Quick LINK top-up (2 LINK)
cast send $LINK_ADDRESS "transfer(address,uint256)" \
  $BUNDLE_EXECUTOR_ADDRESS 2000000000000000000 \
  --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Quick WETH top-up (5 WETH)  
cast send $WETH_ADDRESS "mint(address,uint256)" \
  $BUNDLE_EXECUTOR_ADDRESS 5000000000000000000 \
  --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Quick ETH top-up (0.005 ETH)
cast send --value 0.005ether $BUNDLE_EXECUTOR_ADDRESS \
  --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Quick CCIP-BnM from faucet
cast send $CCIP_BNM_ADDRESS "drip(address)" $BUNDLE_EXECUTOR_ADDRESS \
  --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

---

## 🚨 **Troubleshooting Guide**

### **Common Issues & Solutions**

#### **1. "checkUpkeep returns false" / Plan expired**
```bash
# Plans expire after 5 minutes! Store fresh plan:
cast send $FUNCTIONS_CONSUMER_ADDRESS "storeTestPlan()" \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

#### **2. "RemoteExecutorNotSet" error**
```bash
# Verify circular dependencies are set
cast call $BUNDLE_EXECUTOR_ADDRESS "remoteExecutorSet()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast call $REMOTE_EXECUTOR_ADDRESS "authorizedSenderSet()" --rpc-url $ARBITRUM_SEPOLIA_RPC_URL

# If false, run the circular address setup again
forge script script/SetCircularAddresses.s.sol:SetCircularAddresses \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL --broadcast
```

#### **3. Insufficient WETH balance**
```bash
# Check current balance
cast call $WETH_ADDRESS "balanceOf(address)" $BUNDLE_EXECUTOR_ADDRESS --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Add more WETH (5 WETH)
cast send $WETH_ADDRESS "mint(address,uint256)" \
  $BUNDLE_EXECUTOR_ADDRESS 5000000000000000000 \
  --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

#### **4. CCIP Send Fails (Insufficient LINK)**
```bash
# Check LINK balance
cast call $LINK_ADDRESS "balanceOf(address)" $BUNDLE_EXECUTOR_ADDRESS --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Add more LINK (2 LINK)
cast send $LINK_ADDRESS "transfer(address,uint256)" \
  $BUNDLE_EXECUTOR_ADDRESS 2000000000000000000 \
  --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

#### **5. Gas Price Too High**
```bash
# Check current vs max gas price
cast gas-price --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast call $BUNDLE_EXECUTOR_ADDRESS "maxGasPrice()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Increase max gas price if needed (owner only)
cast send $BUNDLE_EXECUTOR_ADDRESS "setMaxGasPrice(uint256)" \
  100000000000 \
  --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

#### **6. Wrong Contract Configuration**
```bash
# Check PlanStore configuration
cast call $PLAN_STORE_ADDRESS "bundleExecutor()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast call $PLAN_STORE_ADDRESS "functionsConsumer()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Update if wrong (owner only)
cast send $PLAN_STORE_ADDRESS "setBundleExecutor(address)" $BUNDLE_EXECUTOR_ADDRESS \
  --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

---

## ✅ **Deployment Checklist**

### **Pre-Deployment**
- [ ] Environment variables configured
- [ ] Private key has testnet ETH on both chains
- [ ] AWS Bedrock access configured
- [ ] Alchemy RPC endpoints working

### **Contract Deployment**
- [ ] Ethereum contracts deployed and verified
- [ ] Arbitrum contracts deployed and verified
- [ ] Circular dependencies resolved
- [ ] Contract integration verified

### **Funding**
- [ ] BundleExecutor has >= 0.01 ETH for gas
- [ ] BundleExecutor has >= 10 WETH for sustained trading
- [ ] BundleExecutor has >= 5 LINK for fees
- [ ] RemoteExecutor has >= 0.005 ETH for gas
- [ ] Liquidity pools set up on both chains

### **Services Registration**
- [ ] Chainlink Functions subscription created and funded
- [ ] Functions Consumer added to subscription
- [ ] Functions Consumer time-based automation registered (every 5 min)
- [ ] Bundle Executor custom logic automation registered
- [ ] Both automations funded with LINK
- [ ] API server deployed and accessible

### **Testing**
- [ ] Manual test plan storage successful
- [ ] Automation conditions working
- [ ] Cross-chain execution successful
- [ ] CCIP messages tracked on explorer

### **Monitoring Setup**
- [ ] Balance monitoring alerts
- [ ] Automation execution tracking
- [ ] CCIP message monitoring
- [ ] API health checks

---

## 💯 **Production Readiness**

### **Security Considerations**
- **Private Key Security**: Use hardware wallets or secure key management for mainnet
- **Contract Verification**: All contracts should be verified on block explorers
- **Access Control**: Ensure only authorized addresses can call admin functions
- **Emergency Procedures**: Have emergency stop mechanisms ready

### **Scaling Considerations**
- **Gas Optimization**: Monitor gas usage and optimize for efficiency
- **Balance Management**: Set up automated balance monitoring and refilling
- **Multi-Chain Expansion**: Consider deploying on additional chain pairs
- **Profit Optimization**: Fine-tune parameters for maximum profitability

### **Maintenance Schedule**
- **Daily**: Check balances and system health
- **Weekly**: Review execution history and performance
- **Monthly**: Update parameters based on market conditions
- **Quarterly**: Review and update security measures

---

## 🎯 **Success Metrics**

### **Expected Performance**
- **Response Time**: ~30 seconds end-to-end execution
- **Success Rate**: 95%+ successful arbitrage completions
- **Gas Efficiency**: Optimized for profitable execution
- **Uptime**: 99%+ system availability

### **Monitoring KPIs**
- Arbitrage opportunities detected per day
- Successful vs failed executions
- Average profit per trade
- System downtime incidents
- Gas cost optimization

---

## 🏆 **Congratulations!**

You've successfully deployed your own CrossLink Arbitor system! Your autonomous cross-chain arbitrage protocol is now:

- ✅ **Fully Deployed** on both Ethereum and Arbitrum Sepolia
- ✅ **Properly Funded** with all required tokens
- ✅ **Chainlink Integrated** with Functions, Automation, and CCIP
- ✅ **AI-Powered** with Amazon Bedrock intelligence
- ✅ **Production Ready** for autonomous operation

### **Next Steps**
1. **Monitor Performance**: Track executions and optimize parameters
2. **Scale Up**: Add more liquidity or expand to other chains
3. **Mainnet Deployment**: When ready, deploy to production networks
4. **Community**: Share your experience and contribute improvements

---

**Happy Arbitraging! 🚀**

For support, check our [documentation](../README.md) or join our community channels.
 