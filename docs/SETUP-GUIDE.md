# 🔧 Setup Guide - What You Need to Do Next

## 📋 Current Status

✅ **FIXED**: BundleExecutor now sends CCIP messages to correct RemoteExecutor  
✅ **DEPLOYED**: All contracts redeployed with proper configuration  
✅ **VERIFIED**: Remote Executor address is correct: `0xE6C31609f971A928BB6C98Ca81A01E2930496137`

---

## 🚨 URGENT: Register New Chainlink Automation Upkeep

### Why This Is Required
Your **old Chainlink Automation upkeep is pointing to the wrong BundleExecutor address**. You need to register a new one.

### Step 1: Go to Chainlink Automation
1. Visit: https://automation.chain.link/
2. Connect your wallet (`0xbb0235ADdc0d3C23bF3904Fc47EB6284328fFB5E`)
3. Click **"Register New Upkeep"**

### Step 2: Configure the Upkeep
```
Upkeep Name: Cross-Chain Arbitrage Bot (NEW)
Target Contract: 0x9b2a205d2E48ED34AA4c9756E3BBc540Ff6c74cd
Trigger Type: Custom Logic (NOT time-based)
Gas Limit: 1,000,000
Starting Balance: 5 LINK (minimum)
Admin Address: 0xbb0235ADdc0d3C23bF3904Fc47EB6284328fFB5E
```

### Step 3: Fund the Upkeep
- Transfer **5+ LINK tokens** to fund the upkeep
- The upkeep will automatically call `checkUpkeep()` every ~15 seconds
- When conditions are met, it will call `performUpkeep()`

---

## 💰 Fund Your Contracts

### Current Contract Balances
Run these commands to check:

```bash
# Check BundleExecutor WETH balance
cast call 0x9871314Bd78FE5191Cfa2145f2aFe1843624475A "balanceOf(address)" 0x9b2a205d2E48ED34AA4c9756E3BBc540Ff6c74cd --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Check BundleExecutor CCIP-BnM balance  
cast call 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05 "balanceOf(address)" 0x9b2a205d2E48ED34AA4c9756E3BBc540Ff6c74cd --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Check BundleExecutor LINK balance
cast call 0x779877A7B0D9E8603169DdbD7836e478b4624789 "balanceOf(address)" 0x9b2a205d2E48ED34AA4c9756E3BBc540Ff6c74cd --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

### Required Funding
The BundleExecutor needs:
- **✅ 10 WETH** (already funded)
- **✅ 0.1 LINK** (already funded) 
- **✅ 0.5 CCIP-BnM** (already funded)

---

## 🧪 Test the System Manually

### Option 1: Using the Provided Script
```bash
forge script script/ExecuteAndGetCCIP.s.sol \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL \
  --broadcast \
  --private-key $PRIVATE_KEY \
  -vv
```

### Option 2: Manual Step-by-Step Testing
```bash
# 1. Store a test plan
cast send 0x2eEbcC4807A0a8C95610E764369D0eeCEC5a655f "storeTestPlan()" \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# 2. Check if automation conditions are met
cast call 0x9b2a205d2E48ED34AA4c9756E3BBc540Ff6c74cd "checkUpkeep(bytes)" 0x \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# 3. If checkUpkeep returns true, manually trigger execution
cast send 0x9b2a205d2E48ED34AA4c9756E3BBc540Ff6c74cd "performUpkeep(bytes)" 0x \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --gas-limit 1000000
```

---

## 📊 How to See CCIP Messages

### When Execution Works, You'll See:
1. **Transaction Receipt** with CCIP events
2. **CCIP Explorer**: https://ccip.chain.link/
3. **Message Details**:
   - From: Ethereum Sepolia
   - To: Arbitrum Sepolia  
   - Receiver: `0xE6C31609f971A928BB6C98Ca81A01E2930496137`
   - Token: CCIP-BnM amount

### Example Successful Execution Log:
```
✅ WETH swapped to CCIP-BnM on Ethereum
✅ CCIP message sent to Arbitrum
✅ Receiver: 0xE6C31609f971A928BB6C98Ca81A01E2930496137
✅ Check CCIP Explorer for message status
```

---

## 🔄 Automation Workflow

Once your Chainlink Automation is registered:

```
1. ⏰ Every ~15 seconds: Automation calls checkUpkeep()
2. 📊 Checks: Active plan exists + sufficient balance + gas price OK
3. ⚡ If conditions met: Calls performUpkeep()
4. 🔄 Executes: WETH → CCIP-BnM swap + CCIP message
5. 🎯 Result: Tokens sent to RemoteExecutor on Arbitrum
```

---

## ⚠️ Troubleshooting

### If performUpkeep Fails:
1. **"No valid plan"**: Store a fresh plan using `storeTestPlan()`
2. **Insufficient balance**: Fund with more WETH/LINK/CCIP-BnM
3. **Gas price too high**: Wait for lower gas prices or increase limit

### If checkUpkeep Returns False:
1. **No active plan**: Call `storeTestPlan()` first
2. **Insufficient WETH**: BundleExecutor needs ≥1 WETH  
3. **Gas price exceeded**: Current gas > 50 gwei limit

### If CCIP Message Fails:
1. **Insufficient LINK**: Need ~0.04 LINK for CCIP fees
2. **Invalid receiver**: Should be `0xE6C31609f971A928BB6C98Ca81A01E2930496137`

---

## 🎯 Success Indicators

### You'll Know It's Working When:
- ✅ Chainlink Automation shows "Upkeep Performed" 
- ✅ BundleExecutor WETH balance decreases
- ✅ CCIP Explorer shows messages to `0xE6C31609f971A928BB6C98Ca81A01E2930496137`
- ✅ RemoteExecutor receives tokens on Arbitrum

---

## 📞 Next Steps Summary

1. **🔴 REGISTER NEW AUTOMATION** (critical - old one won't work)
2. **🟡 Test manually** to verify flow works
3. **🟢 Monitor automation** once registered
4. **📈 Check CCIP Explorer** for cross-chain messages

**The core fix is complete - you just need to register the new automation upkeep! 🚀** 
