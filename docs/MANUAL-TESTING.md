# Manual Testing Guide

## Environment Setup
```bash
export PRIVATE_KEY=0x9971812261ecfc8d83860eaceff14ab42748678da818e0ab8a586f6dde6adb2d
export ETHEREUM_SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/xiJw6cj_7U8PXLSncrSON78PWDXP4Dkl
export ARBITRUM_SEPOLIA_RPC_URL=https://arb-sepolia.g.alchemy.com/v2/xiJw6cj_7U8PXLSncrSON78PWDXP4Dkl

export BUNDLE_EXECUTOR=0xB20412c4403277A6dD64e0D0dCa19F81b5412cBA
export PLAN_STORE=0x1177D6F59e9877D6477743C6961988D86ee78174
export FUNCTIONS_CONSUMER=0x59c6AC86b75Caf8FC79782F79C85B8588211b6C2
export REMOTE_EXECUTOR=0x45ee7AA56775aB9385105393458FC4e56b4B578c
```

## Contract Verification

### Check Circular Dependencies (NEW!)
```bash
# Verify BundleExecutor knows RemoteExecutor
cast call $BUNDLE_EXECUTOR "remoteExecutor()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
# Should return: 0x45ee7AA56775aB9385105393458FC4e56b4B578c

# Verify RemoteExecutor knows BundleExecutor  
cast call $REMOTE_EXECUTOR "authorizedSender()" --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
# Should return: 0xB20412c4403277A6dD64e0D0dCa19F81b5412cBA

# Verify setter flags are set
cast call $BUNDLE_EXECUTOR "remoteExecutorSet()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
# Should return: true

cast call $REMOTE_EXECUTOR "authorizedSenderSet()" --rpc-url $ARBITRUM_SEPOLIA_RPC_URL  
# Should return: true
```

### Check PlanStore Configuration
```bash
# Verify PlanStore knows the correct BundleExecutor
cast call $PLAN_STORE "bundleExecutor()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
# Should return: 0x000000000000000000000000b20412c4403277a6dd64e0d0dca19f81b5412cba

# If wrong BundleExecutor address, update it (owner only):
cast send $PLAN_STORE "setBundleExecutor(address)" $BUNDLE_EXECUTOR \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

cast send --private-key $PRIVATE_KEY $PLAN_STORE "setFunctionsConsumer(address)" $FUNCTIONS_CONSUMER \ --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Verify Functions Consumer is set correctly
cast call $PLAN_STORE "functionsConsumer()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
# Should return: 0x0000000000000000000000002eebcc4807a0a8c95610e764369d0eecec5a655f
```

## Balance Checks

### Ethereum Sepolia
```bash
# WETH balance
cast call 0xe95595f0BE77d6CF079795Ed63942933E9a6bf7b "balanceOf(address)" $BUNDLE_EXECUTOR --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
# LINK balance  
cast call 0x779877A7B0D9E8603169DdbD7836e478b4624789 "balanceOf(address)" $BUNDLE_EXECUTOR --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

### Arbitrum Sepolia
```bash
# WETH balance
cast call 0x21ADF7b3F3AeA141E0b8544bF9de7e1e0CA21578 "balanceOf(address)" $REMOTE_EXECUTOR --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

## Pool Analysis

### Current Pool States

#### Ethereum Sepolia Pool
```bash
# Check current reserves
cast call 0xd7471664f91C43c5c3ed2B06734b4a392D94Fe16 "getReserves()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Expected format: (reserve0, reserve1, blockTimestampLast)
# reserve0 = WETH amount, reserve1 = CCIP-BnM amount
```

#### Arbitrum Sepolia Pool  
```bash
# Check current reserves
cast call 0xAc6D3a904c37c4B75F1823d1B0238d6d48D8bfB3 "getReserves()" --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

## Test Functions Execution

### 1. Store Arbitrage Plan
```bash
# Store test plan via Functions Consumer (bypasses real Functions call)
cast send $FUNCTIONS_CONSUMER "storeTestPlan()" \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# OR use the full execution script
forge script script/ExecuteAndGetCCIP.s.sol --rpc-url $ETHEREUM_SEPOLIA_RPC_URL --broadcast
```

### 2. Check Plan Storage
```bash
# Check if plan should execute (expires after 5 minutes!)
cast call $PLAN_STORE "shouldExecute()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
# Should return: 0x0000000000000000000000000000000000000000000000000000000000000001 (true)

# Get full plan details
cast call $PLAN_STORE "getCurrentPlan()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
# Returns: (execute, amount, minEdgeBps, maxGasGwei, timestamp)
# Example: execute=true, amount=1000000000000000000 (1 ETH), minEdgeBps=50, maxGasGwei=50, timestamp=1750548636
```

### 3. Test Manual BundleExecutor

#### Check Automation Conditions
```bash
# Check if upkeep is needed (should return true)
cast call $BUNDLE_EXECUTOR "checkUpkeep(bytes)" 0x --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
# Returns: (upkeepNeeded, performData)
# Expected: 0x000000000000000000000000000000000000000000000000000000000000000100000... (true, empty data)
```

#### Debug Individual Conditions (if checkUpkeep returns false)
```bash
echo "=== DEBUGGING AUTOMATION CONDITIONS ==="

echo "1. Remote Executor Set:"
cast call $BUNDLE_EXECUTOR "remoteExecutorSet()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
# Expected: 0x0000000000000000000000000000000000000000000000000000000000000001 (true)

echo "2. Plan Should Execute:"
cast call $PLAN_STORE "shouldExecute()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
# Expected: 0x0000000000000000000000000000000000000000000000000000000000000001 (true)

echo "3. Gas Price Check:"
cast gas-price --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
echo "Max Gas Price (50 gwei = 50000000000):"
cast call $BUNDLE_EXECUTOR "maxGasPrice()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
# Gas price should be <= 50000000000

echo "4. WETH Balance Check:"
cast call 0xe95595f0BE77d6CF079795Ed63942933E9a6bf7b "balanceOf(address)" $BUNDLE_EXECUTOR --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
echo "Plan Amount Required:"
cast call $PLAN_STORE "getCurrentPlan()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
# WETH balance should be >= plan amount
```

#### Manual Execution (if upkeep needed)
```bash
# Execute manually for testing
cast send $BUNDLE_EXECUTOR "performUpkeep(bytes)" 0x \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --gas-limit 500000
```

### 🚀 Quick Testing Workflow (Beat the 5-minute timer!)
```bash
# Step 1: Store plan
cast send $FUNCTIONS_CONSUMER "storeTestPlan()" --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Step 2: Immediately check conditions (run within 30 seconds)
cast call $PLAN_STORE "shouldExecute()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast call $BUNDLE_EXECUTOR "checkUpkeep(bytes)" 0x --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Step 3: Execute immediately if conditions are met
cast send $BUNDLE_EXECUTOR "performUpkeep(bytes)" 0x --rpc-url $ETHEREUM_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --gas-limit 500000
```

### 4. Monitor CCIP Messages
After execution, check:
- Transaction hash from performUpkeep call
- Look for ArbitrageExecuted event with CCIP messageId
- Track message on CCIP Explorer: https://ccip.chain.link/

## Balance Verification After Execution

### Ethereum Side
```bash
# Check remaining WETH in BundleExecutor
cast call 0xe95595f0BE77d6CF079795Ed63942933E9a6bf7b "balanceOf(address)" $BUNDLE_EXECUTOR --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Check CCIP-BnM sent
cast call 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05 "balanceOf(address)" $BUNDLE_EXECUTOR --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

### Arbitrum Side  
```bash
# Check WETH received by RemoteExecutor
cast call 0x21ADF7b3F3AeA141E0b8544bF9de7e1e0CA21578 "balanceOf(address)" 0x28ea4eF61ac4cca3ed6a64dBb5b2D4be1aDC9814 --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

## Automation Setup

### Chainlink Automation Registration
- **Network**: Ethereum Sepolia
- **Target**: `0xB20412c4403277A6dD64e0D0dCa19F81b5412cBA`
- **Admin**: `0xbb0235ADdc0d3C23bF3904Fc47EB6284328fFB5E`
- **Check Data**: `0x` (empty)
- **Gas Limit**: `500,000`
- **Trigger**: Custom Logic

### Expected Flow:
1. ✅ Functions Consumer stores profitable plan
2. ✅ Automation detects plan via checkUpkeep()
3. ✅ BundleExecutor executes arbitrage via performUpkeep()
4. ✅ CCIP message sent to RemoteExecutor with tokens
5. ✅ RemoteExecutor completes arbitrage and sends profit to treasury

## Troubleshooting

### Common Issues:

1. **checkUpkeep returns false / Plan expired**
   ```bash
   # Plans expire after 5 minutes! Store fresh plan:
   cast send $FUNCTIONS_CONSUMER "storeTestPlan()" \
     --private-key $PRIVATE_KEY \
     --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
   ```

2. **"No valid plan" error**
   - Check if Functions Consumer has stored a plan
   - Verify plan hasn't expired (5 minute limit)
   - Store fresh plan using command above

3. **"RemoteExecutorNotSet" error**  
   ```bash
   # Run the SetCircularAddresses script
   export REMOTE_EXECUTOR_ADDRESS=0x45ee7AA56775aB9385105393458FC4e56b4B578c
   forge script script/SetCircularAddresses.s.sol:SetCircularAddresses \
     --rpc-url $ETHEREUM_SEPOLIA_RPC_URL --broadcast
   ```

4. **Gas price too high**
   ```bash
   # Check current vs max gas price
   cast gas-price --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
   cast call $BUNDLE_EXECUTOR "maxGasPrice()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
   # If needed, increase max gas price (owner only)
   ```

5. **Insufficient WETH balance**
   ```bash
   # Add more WETH to BundleExecutor
   cast send 0xe95595f0BE77d6CF079795Ed63942933E9a6bf7b "mint(address,uint256)" \
     $BUNDLE_EXECUTOR 1000000000000000000 \
     --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
   ```

6. **Plan expiration timing (CRITICAL)**
   - **Plans expire after 5 minutes** - this is the #1 cause of issues
   - **Automation checks every 30s-2min** - might miss short-lived plans
   - **Solution 1**: Store plan → immediately test manually
   - **Solution 2**: Set up real Chainlink Functions for continuous plan generation
   - **Testing tip**: Run commands in quick succession after storing plan

7. **Wrong BundleExecutor in PlanStore**
   ```bash
   # Check current BundleExecutor in PlanStore
   cast call $PLAN_STORE "bundleExecutor()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
   
   # Update if wrong (owner only)
   cast send $PLAN_STORE "setBundleExecutor(address)" $BUNDLE_EXECUTOR \
     --private-key $PRIVATE_KEY \
     --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
   ```

### New Architecture Benefits:
- 🔒 **Clean Setup**: No more dummy addresses 
- ✅ **Proper Auth**: Circular dependencies resolved cleanly
- 🚀 **Reliable**: One-time setters prevent configuration issues
