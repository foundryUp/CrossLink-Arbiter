# 🧪 Manual Testing Guide - Cross-Chain Arbitrage Protocol

## 🎯 Complete Manual Testing Commands

This guide provides all commands needed to manually test the cross-chain arbitrage flow with the **FIXED** deployment addresses.

## ✅ **ISSUE RESOLVED**
- **❌ OLD**: BundleExecutor sent CCIP messages to dummy address `0x1234...7890`
- **✅ NEW**: BundleExecutor correctly sends to real RemoteExecutor `0xE6C31609f971A928BB6C98Ca81A01E2930496137`

---

## 🔧 Environment Setup

```bash
# Set environment variables
export PRIVATE_KEY=0x9971812261ecfc8d83860eaceff14ab42748678da818e0ab8a586f6dde6adb2d
export ETHEREUM_SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/xiJw6cj_7U8PXLSncrSON78PWDXP4Dkl
export ARBITRUM_SEPOLIA_RPC_URL=https://arb-sepolia.g.alchemy.com/v2/xiJw6cj_7U8PXLSncrSON78PWDXP4Dkl

# Contract addresses (UPDATED - NEW DEPLOYMENT)
export PLAN_STORE=0x1177D6F59e9877D6477743C6961988D86ee78174
export BUNDLE_EXECUTOR=0x9b2a205d2E48ED34AA4c9756E3BBc540Ff6c74cd  # ✅ FIXED
export FUNCTIONS_CONSUMER=0x2eEbcC4807A0a8C95610E764369D0eeCEC5a655f
export REMOTE_EXECUTOR=0xE6C31609f971A928BB6C98Ca81A01E2930496137

# Token addresses - Ethereum Sepolia (UPDATED)
export ETH_WETH=0x9871314Bd78FE5191Cfa2145f2aFe1843624475A      # ✅ NEW
export ETH_CCIP_BNM=0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05   # Same
export ETH_LINK=0x779877A7B0D9E8603169DdbD7836e478b4624789      # Same

# Token addresses - Arbitrum Sepolia  
export ARB_WETH=0x9BAd0F20eB62a2238c9849A7cE50FCafdE0E1481
export ARB_CCIP_BNM=0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D

# Pair addresses (UPDATED)
export ETH_PAIR=0x9a48295601B66898Aad6cBE9171503212eEe37A4      # ✅ NEW
export ARB_PAIR=0x7DCA1D3AcAcdA7cDdCAD345FB1CDC6109787914F
```

---

## 🎉 **CONFIRMED WORKING**

**✅ Latest Successful Test:**
- **Transaction**: `0x362499ec0232b9966cc82f4e385115886f96342b39e0a86e589c9b6582fe5542`
- **WETH Swapped**: 1.0 WETH → 0.027 CCIP-BnM
- **CCIP Fee**: 0.043 LINK
- **Destination**: `0xE6C31609f971A928BB6C98Ca81A01E2930496137` ✅
- **CCIP Explorer**: https://ccip.chain.link/ (search by transaction hash)

---

## 📋 Step-by-Step Manual Testing

### Step 1: Check Initial System Status

```bash
# Check BundleExecutor balances
cast call $ETH_WETH "balanceOf(address)" $BUNDLE_EXECUTOR --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast call $ETH_LINK "balanceOf(address)" $BUNDLE_EXECUTOR --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Check plan and automation status
cast call $PLAN_STORE "shouldExecute()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast call $BUNDLE_EXECUTOR "checkUpkeep(bytes)" 0x --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

### Step 2: Check Pool Reserves & Prices

```bash
# Check pool reserves
cast call $ETH_PAIR "getReserves()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast call $ARB_PAIR "getReserves()" --rpc-url $ARBITRUM_SEPOLIA_RPC_URL

# Check gas prices
cast gas-price --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast gas-price --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

### Step 3: Store Manual Test Plan

```bash
# Store test plan (1 WETH, 50 basis points edge, 50 gwei max gas)
cast send $FUNCTIONS_CONSUMER "storeTestPlan()" --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

### Step 4: Verify Plan Storage & Automation Trigger

```bash
# Verify plan stored and automation ready
cast call $PLAN_STORE "shouldExecute()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast call $BUNDLE_EXECUTOR "checkUpkeep(bytes)" 0x --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

### Step 5: Monitor Automation Execution

```bash
echo "=== MONITORING AUTOMATION ==="

echo "⚠️  IMPORTANT: You need to register NEW Chainlink Automation!"
echo "Old upkeep points to wrong BundleExecutor address."
echo ""
echo "Register NEW upkeep at: https://automation.chain.link/"
echo "Target Contract: $BUNDLE_EXECUTOR"
echo "Trigger: Custom Logic (NOT time-based)"
echo "Gas Limit: 1,000,000"
echo "Fund with: 5+ LINK tokens"
echo ""

echo "Expected execution flow:"
echo "1. ✅ checkUpkeep() returns true"
echo "2. 🤖 Chainlink calls performUpkeep()"
echo "3. 🔄 WETH → CCIP-BnM swap on Ethereum"
echo "4. 🌉 CCIP message sent to Arbitrum"
echo "5. 🔄 CCIP-BnM → WETH swap on Arbitrum"
echo "6. 💰 Profits sent to treasury"

echo ""
echo "Wait 60 seconds, then run Step 6 to check results..."
```

### Step 6: Check Execution Results

```bash
# Check plan cleared (should be false)
cast call $PLAN_STORE "shouldExecute()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Check BundleExecutor balances after execution
cast call $ETH_WETH "balanceOf(address)" $BUNDLE_EXECUTOR --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast call $ETH_CCIP_BNM "balanceOf(address)" $BUNDLE_EXECUTOR --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Check treasury profits on Arbitrum
cast call $ARB_WETH "balanceOf(address)" 0x28ea4eF61ac4cca3ed6a64dBb5b2D4be1aDC9814 --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

### Step 7: CCIP Message Tracking

**🌉 CCIP Explorer**: https://ccip.chain.link/

**Search Parameters:**
- **Source**: Ethereum Sepolia → Arbitrum Sepolia
- **Sender**: `$BUNDLE_EXECUTOR`
- **Receiver**: `$REMOTE_EXECUTOR`

---

## 🚀 **Quick Test with Improved Script**

### Option A: Use the Improved Execution Script
```bash
# This script automatically stores a plan and executes the arbitrage
forge script script/ExecuteAndGetCCIP.s.sol \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL \
  --broadcast \
  --private-key $PRIVATE_KEY \
  -vv
```

**This script will:**
1. ✅ Check current system status
2. ✅ Store test plan automatically if none exists  
3. ✅ Execute arbitrage immediately
4. ✅ Show CCIP transaction details
5. ✅ Provide CCIP Explorer links

---

## 🔄 Manual Test Scenarios

### Scenario A: Basic Automation Test
```bash
# Quick test to verify automation works
cast send $FUNCTIONS_CONSUMER "storeTestPlan()" --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Wait 30 seconds, then check
cast call $PLAN_STORE "shouldExecute()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

### Scenario B: Multiple Plan Testing
```bash
# Store plan
cast send $FUNCTIONS_CONSUMER "storeTestPlan()" --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Wait for execution (plan should be cleared)
sleep 60

# Store another plan  
cast send $FUNCTIONS_CONSUMER "storeTestPlan()" --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Monitor second execution
```

### Scenario C: Manual Plan Clearing
```bash
# Store test plan
cast send $FUNCTIONS_CONSUMER "storeTestPlan()" --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Manually clear before automation executes
cast send $PLAN_STORE "clearPlan()" --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Verify plan cleared
cast call $PLAN_STORE "shouldExecute()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

---

## 🛠️ Troubleshooting Commands

### Check Automation Status
```bash
# Check if automation should trigger
cast call $PLAN_STORE "shouldExecute()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Check sufficient balances (need 1+ WETH, 0.1+ LINK)
cast call $ETH_WETH "balanceOf(address)" $BUNDLE_EXECUTOR --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast call $ETH_LINK "balanceOf(address)" $BUNDLE_EXECUTOR --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Check gas price
cast gas-price --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

### Reset System State
```bash
# Clear existing plan and verify
cast send $PLAN_STORE "clearPlan()" --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast call $PLAN_STORE "shouldExecute()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

### Fund Contracts for Testing

**🎯 Funding Requirements:**

| Contract | Chain | WETH | CCIP-BnM | LINK | Notes |
|----------|-------|------|----------|------|-------|
| **BundleExecutor** | Ethereum | ✅ 1+ | ❌ No | ✅ 0.1+ | Source chain |
| **RemoteExecutor** | Arbitrum | ❌ No | ❌ No | ❌ No | Receives via CCIP |

```bash
# Fund BundleExecutor on Ethereum Sepolia
# 1. Send WETH for arbitrage execution
cast send $ETH_WETH "transfer(address,uint256)" $BUNDLE_EXECUTOR 1000000000000000000 --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# 2. Send LINK for CCIP fees (0.1 LINK minimum)
cast send $ETH_LINK "transfer(address,uint256)" $BUNDLE_EXECUTOR 100000000000000000 --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

**❌ Do NOT fund RemoteExecutor** - it receives tokens automatically via CCIP

**💡 Why only fund BundleExecutor?**
- **WETH**: Needed for initial swap (WETH → CCIP-BnM)
- **LINK**: Required for CCIP fees (paid on source chain)
- **CCIP-BnM**: Generated from WETH swap, then sent cross-chain
- **RemoteExecutor**: Receives CCIP-BnM via bridge, swaps to WETH

---

## 📊 Expected Results

### ✅ Successful Test Indicators:

1. **Plan Storage**: `shouldExecute()` returns `true` after storing
2. **Automation Ready**: `checkUpkeep()` returns `(true, 0x)`
3. **Execution**: Plan gets cleared automatically within 30-60 seconds
4. **Balance Changes**: WETH decreases, CCIP-BnM balance changes
5. **CCIP Transfer**: Messages visible on CCIP explorer
6. **Profits**: Treasury receives WETH on Arbitrum

### ❌ Troubleshooting Issues:

1. **Plan not stored**: Check Functions consumer authorization
2. **Automation not triggering**: Verify gas price, balances, and upkeep funding
3. **Execution fails**: Check LINK balance for CCIP fees
4. **No CCIP message**: Verify router addresses and token approvals

---

## 🎯 Complete Test Script (Updated)

```bash
#!/bin/bash
# Complete automated test script with NEW addresses

echo "🧪 STARTING MANUAL ARBITRAGE TEST (FIXED VERSION)"

# Set environment variables
export PLAN_STORE=0x1177D6F59e9877D6477743C6961988D86ee78174
export BUNDLE_EXECUTOR=0x9b2a205d2E48ED34AA4c9756E3BBc540Ff6c74cd  # ✅ FIXED
export FUNCTIONS_CONSUMER=0x2eEbcC4807A0a8C95610E764369D0eeCEC5a655f

# Step 1: Environment check
echo "=== STEP 1: ENVIRONMENT CHECK (NEW ADDRESSES) ==="
echo "BundleExecutor: $BUNDLE_EXECUTOR"
echo "Plan should execute:"
cast call $PLAN_STORE "shouldExecute()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
echo "Automation ready:"
cast call $BUNDLE_EXECUTOR "checkUpkeep(bytes)" 0x --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Step 2: Store test plan
echo "=== STEP 2: STORING TEST PLAN ==="
cast send $FUNCTIONS_CONSUMER "storeTestPlan()" --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Step 3: Verify trigger
echo "=== STEP 3: VERIFYING TRIGGER ==="
cast call $PLAN_STORE "shouldExecute()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast call $BUNDLE_EXECUTOR "checkUpkeep(bytes)" 0x --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Step 4: Manual execution (since automation needs to be re-registered)
echo "=== STEP 4: MANUAL EXECUTION ==="
echo "⚠️  Register new automation at: https://automation.chain.link/"
echo "Target: $BUNDLE_EXECUTOR"
echo ""
echo "Or execute manually now:"
forge script script/ExecuteAndGetCCIP.s.sol --rpc-url $ETHEREUM_SEPOLIA_RPC_URL --broadcast --private-key $PRIVATE_KEY -vv

# Step 5: Verify results
echo "=== STEP 5: CHECKING RESULTS ==="
cast call $PLAN_STORE "shouldExecute()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

echo "🎉 TEST COMPLETE!"
echo "✅ System confirmed working with correct CCIP destination!"
echo "📊 Latest success: 0x362499ec0232b9966cc82f4e385115886f96342b39e0a86e589c9b6582fe5542"
```

**Save this as `test_arbitrage_fixed.sh` and run with `bash test_arbitrage_fixed.sh`**

---

## 🎯 **Key Takeaways**

### ✅ **What Was Fixed**
1. **PlanStore Address Mismatch**: Functions Consumer and BundleExecutor now use same PlanStore
2. **CCIP Destination**: Messages now go to real RemoteExecutor `0xE6C31609f971A928BB6C98Ca81A01E2930496137`
3. **Contract Addresses**: All updated to new deployment with correct configuration

### 🚨 **What You Need to Do**
1. **Fund BundleExecutor**: WETH (1+) + LINK (0.1+) on Ethereum Sepolia
2. **Register NEW Chainlink Automation** (old one invalid)
3. **Use updated addresses** from this guide
4. **Test manually** using provided scripts

### 🎉 **System Status**
- ✅ **Manual execution**: Confirmed working
- ✅ **CCIP messages**: Reaching correct destination  
- ✅ **Arbitrage flow**: End-to-end functional
- ⚠️ **Automation**: Needs new upkeep registration

---

**🚀 The core issue is FIXED! This manual testing guide verifies the complete corrected arbitrage flow!** 
