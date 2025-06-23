# Contract Funding Guide

This guide covers ALL funding requirements and commands for the Chainlink cross-chain arbitrage system.

## 🎯 Required Funding Summary

### BundleExecutor (`0xB20412c4403277A6dD64e0D0dCa19F81b5412cBA`) - Ethereum Sepolia
- ✅ **ETH**: 0.005 ETH (for gas costs) 
- ✅ **WETH**: 1.6 WETH total (0.5 initial + 1.5 emergency)
- ✅ **LINK**: 0.1 LINK total (0.05 initial + 0.05 emergency)
- 💡 **CCIP-BnM**: Variable (from faucet/transfers as needed)

### RemoteExecutor (`0x45ee7AA56775aB9385105393458FC4e56b4B578c`) - Arbitrum Sepolia 
- ✅ **ETH**: 0.003 ETH (for gas costs)
- 💡 **WETH**: Not needed initially (received via arbitrage)
- 💡 **CCIP-BnM**: Not needed initially (received via CCIP)

## 🔧 Environment Setup

```bash
# Core environment variables
export PRIVATE_KEY=0x9971812261ecfc8d83860eaceff14ab42748678da818e0ab8a586f6dde6adb2d
export ETHEREUM_SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/xiJw6cj_7U8PXLSncrSON78PWDXP4Dkl
export ARBITRUM_SEPOLIA_RPC_URL=https://arb-sepolia.g.alchemy.com/v2/xiJw6cj_7U8PXLSncrSON78PWDXP4Dkl

# Contract addresses
export BUNDLE_EXECUTOR_ADDRESS=0xB20412c4403277A6dD64e0D0dCa19F81b5412cBA
export REMOTE_EXECUTOR_ADDRESS=0x45ee7AA56775aB9385105393458FC4e56b4B578c

# Ethereum Sepolia token addresses
export WETH_ADDRESS=0xe95595f0BE77d6CF079795Ed63942933E9a6bf7b
export CCIP_BNM_ADDRESS=0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05
export LINK_ADDRESS=0x779877A7B0D9E8603169DdbD7836e478b4624789

# Arbitrum Sepolia token addresses
export ARB_WETH_ADDRESS=0x21ADF7b3F3AeA141E0b8544bF9de7e1e0CA21578
export ARB_CCIP_BNM_ADDRESS=0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D
```

## 💰 Step-by-Step Funding Process

### Step 1: Initial BundleExecutor Funding (Ethereum Sepolia)

#### 1.1 Send ETH for Gas Costs
```bash
cast send --value 0.005ether $BUNDLE_EXECUTOR_ADDRESS \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```
**✅ Expected Result**: Transaction hash, ~0.005 ETH balance

#### 1.2 Mint Initial WETH (0.5 WETH)
```bash
cast send $WETH_ADDRESS "mint(address,uint256)" \
  $BUNDLE_EXECUTOR_ADDRESS 500000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```
**✅ Expected Result**: 0.5 WETH balance

#### 1.3 Transfer Initial LINK (0.05 LINK)
```bash
cast send $LINK_ADDRESS "transfer(address,uint256)" \
  $BUNDLE_EXECUTOR_ADDRESS 50000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```
**✅ Expected Result**: 0.05 LINK balance

### Step 2: Fund RemoteExecutor (Arbitrum Sepolia)

#### 2.1 Send ETH for Gas Costs
```bash
cast send --value 0.003ether $REMOTE_EXECUTOR_ADDRESS \
  --private-key $PRIVATE_KEY \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```
**✅ Expected Result**: Transaction hash, ~0.003 ETH balance

### Step 3: Emergency/Additional Funding (When Needed)

#### 3.1 Additional WETH (1.5 WETH more)
```bash
# Required when BundleExecutor needs >= 1 WETH for execution
cast send $WETH_ADDRESS "mint(address,uint256)" \
  $BUNDLE_EXECUTOR_ADDRESS 1500000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```
**✅ Result**: Total 2.0 WETH (0.5 + 1.5)

#### 3.2 Additional LINK (0.05 LINK more)
```bash
# Required when CCIP fees exceed current balance (~0.044 LINK needed)
cast send $LINK_ADDRESS "transfer(address,uint256)" \
  $BUNDLE_EXECUTOR_ADDRESS 50000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```
**✅ Result**: Total 0.1 LINK (0.05 + 0.05)

#### 3.3 Additional ETH (If Needed)
```bash
# For extra gas costs if needed
cast send --value 0.002ether $BUNDLE_EXECUTOR_ADDRESS \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# For Arbitrum if needed
cast send --value 0.002ether $REMOTE_EXECUTOR_ADDRESS \
  --private-key $PRIVATE_KEY \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

## 🪙 CCIP-BnM Token Management

### Get CCIP-BnM from Faucets

#### Ethereum Sepolia CCIP-BnM Faucet
```bash
cast send $CCIP_BNM_ADDRESS "drip(address)" \
  $BUNDLE_EXECUTOR_ADDRESS \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

#### Arbitrum Sepolia CCIP-BnM Faucet
```bash
cast send $ARB_CCIP_BNM_ADDRESS "drip(address)" \
  $REMOTE_EXECUTOR_ADDRESS \
  --private-key $PRIVATE_KEY \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

### Transfer CCIP-BnM (If You Have Balance)

#### To BundleExecutor
```bash
cast send $CCIP_BNM_ADDRESS "transfer(address,uint256)" \
  $BUNDLE_EXECUTOR_ADDRESS 1000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

#### To RemoteExecutor
```bash
cast send $ARB_CCIP_BNM_ADDRESS "transfer(address,uint256)" \
  $REMOTE_EXECUTOR_ADDRESS 1000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

## 📊 Balance Verification Commands

### BundleExecutor Balance Checks (Ethereum Sepolia)

#### ETH Balance
```bash
cast balance $BUNDLE_EXECUTOR_ADDRESS --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```
**Expected**: ~5000000000000000 (0.005 ETH)

#### WETH Balance  
```bash
cast call $WETH_ADDRESS "balanceOf(address)" \
  $BUNDLE_EXECUTOR_ADDRESS \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```
**After Full Funding**: 1600000000000000000 (1.6 WETH)

#### LINK Balance
```bash
cast call $LINK_ADDRESS "balanceOf(address)" \
  $BUNDLE_EXECUTOR_ADDRESS \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```
**After Full Funding**: 100000000000000000 (0.1 LINK)

#### CCIP-BnM Balance
```bash
cast call $CCIP_BNM_ADDRESS "balanceOf(address)" \
  $BUNDLE_EXECUTOR_ADDRESS \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```
**Variable**: Depends on faucet/transfers

### RemoteExecutor Balance Checks (Arbitrum Sepolia)

#### ETH Balance
```bash
cast balance $REMOTE_EXECUTOR_ADDRESS --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```
**Expected**: ~3000000000000000 (0.003 ETH)

#### WETH Balance (Arbitrum)
```bash
cast call $ARB_WETH_ADDRESS "balanceOf(address)" \
  $REMOTE_EXECUTOR_ADDRESS \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

#### CCIP-BnM Balance (Arbitrum)
```bash
cast call $ARB_CCIP_BNM_ADDRESS "balanceOf(address)" \
  $REMOTE_EXECUTOR_ADDRESS \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

### Your EOA Balance Checks

#### Check Your LINK Balance
```bash
cast call $LINK_ADDRESS "balanceOf(address)" \
  0xbb0235ADdc0d3C23bF3904Fc47EB6284328fFB5E \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

#### Check Your ETH Balance
```bash
cast balance 0xbb0235ADdc0d3C23bF3904Fc47EB6284328fFB5E --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast balance 0xbb0235ADdc0d3C23bF3904Fc47EB6284328fFB5E --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

## 🚨 Emergency Funding Scenarios

### Scenario 1: CCIP Send Fails (Insufficient LINK)

#### Check LINK Balance
```bash
cast call $LINK_ADDRESS "balanceOf(address)" \
  $BUNDLE_EXECUTOR_ADDRESS \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

#### Quick LINK Top-up
```bash
# Send 0.1 LINK immediately
cast send $LINK_ADDRESS "transfer(address,uint256)" \
  $BUNDLE_EXECUTOR_ADDRESS 100000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

### Scenario 2: Insufficient WETH Balance

#### Check WETH Balance
```bash
cast call $WETH_ADDRESS "balanceOf(address)" \
  $BUNDLE_EXECUTOR_ADDRESS \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

#### Quick WETH Top-up
```bash
# Mint 1 WETH immediately
cast send $WETH_ADDRESS "mint(address,uint256)" \
  $BUNDLE_EXECUTOR_ADDRESS 1000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

### Scenario 3: Out of Gas (ETH)

#### Quick ETH Top-up
```bash
# Add 0.002 ETH for more gas
cast send --value 0.002ether $BUNDLE_EXECUTOR_ADDRESS \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

### Scenario 4: Need More CCIP-BnM

#### Quick CCIP-BnM from Faucet
```bash
cast send $CCIP_BNM_ADDRESS "drip(address)" \
  $BUNDLE_EXECUTOR_ADDRESS \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

## 🏗️ Liquidity Pool Funding

### Ethereum Sepolia Pool Setup
```bash
forge script script/SetupLiquidity.s.sol \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL \
  --broadcast \
  --private-key $PRIVATE_KEY
```

### Arbitrum Sepolia Pool Setup
```bash
# Set Arbitrum environment variables first
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

## 📈 Funding Verification & Testing

### Complete Balance Check (All at Once)
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

### Test Execution Readiness
```bash
# Check if system is ready for arbitrage
cast call 0x1177D6F59e9877D6477743C6961988D86ee78174 "shouldExecute()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast call $BUNDLE_EXECUTOR_ADDRESS "checkUpkeep(bytes)" 0x --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

## 💯 Actual Funding Results (From Successful Execution)

### Successful Transaction Hashes
- **Initial ETH to BundleExecutor**: `0x30da49ee73da92cff456cd0963966eb6eeb89fc6e9dba664dbcdb822f5f48c6c`
- **Initial WETH mint**: `0x80f6e4c492e66b9b50d2dd5247793f38de9f53e048ac42791927f5e061612c68`
- **Initial LINK transfer**: `0xe688fc104cfc3b460cbf5931b08f8f71279da01e0f5a0ccf7f79dc2cf1e67b4a`
- **Emergency WETH mint**: `0x802fa89c9717093ced8c9df3c370b75103611b05e664428430def6aac43c953d`
- **Emergency LINK transfer**: `0x6022897cc762b2e8b7eefa84e5639bdf6f32705a9dcfc5c4328b0112a8de7b6a`
- **ETH to RemoteExecutor**: `0x90e95e149e494b8d65ede3df95253a47550c35d4cc6743b9af6862e602d6c2f4`

### Final Working Balances (Before Execution)
- **BundleExecutor ETH**: ~0.005 ETH
- **BundleExecutor WETH**: 1.6 WETH 
- **BundleExecutor LINK**: 0.1 LINK
- **RemoteExecutor ETH**: ~0.003 ETH

### Successful Arbitrage Execution
- **Transaction Hash**: `0x3cdb00c162fb2d4538e669cad06fdc964b8d1515d877e8c54c71ffceaf031ed8`
- **CCIP Message ID**: `0xf68b08b649d0d5ffe83770d2ae8339485c53ed7bbbc51a0928ff99a346583c27`
- **WETH Used**: 1.0 WETH
- **LINK Used**: ~0.044 LINK
- **Status**: ✅ **SUCCESS**

## 💸 Total Cost Analysis

### ETH Costs
| Item | Amount | Purpose |
|------|--------|---------|
| BundleExecutor Gas | 0.005 ETH | Transaction fees |
| RemoteExecutor Gas | 0.003 ETH | Transaction fees |
| **Total ETH** | **0.008 ETH** | ✅ **Under 0.01 ETH limit** |

### Token Usage
| Token | Amount | Source | Purpose |
|-------|--------|--------|---------|
| WETH | 2.0 total | Minted free | 1.0 for arbitrage, 0.6 remaining |
| LINK | 0.1 total | From EOA | 0.044 for CCIP fees, 0.0117 remaining |
| CCIP-BnM | Variable | Faucet/transfers | Cross-chain transfers |

## 🎯 Quick Funding Commands Reference

### Essential Daily Commands
```bash
# Quick balance check
cast balance $BUNDLE_EXECUTOR_ADDRESS --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast call $WETH_ADDRESS "balanceOf(address)" $BUNDLE_EXECUTOR_ADDRESS --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast call $LINK_ADDRESS "balanceOf(address)" $BUNDLE_EXECUTOR_ADDRESS --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Quick emergency funding
cast send $WETH_ADDRESS "mint(address,uint256)" $BUNDLE_EXECUTOR_ADDRESS 1000000000000000000 --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast send $LINK_ADDRESS "transfer(address,uint256)" $BUNDLE_EXECUTOR_ADDRESS 100000000000000000 --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

### Emergency One-Liners
```bash
# Emergency LINK (0.1 LINK)
cast send $LINK_ADDRESS "transfer(address,uint256)" $BUNDLE_EXECUTOR_ADDRESS 100000000000000000 --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Emergency WETH (1 WETH)  
cast send $WETH_ADDRESS "mint(address,uint256)" $BUNDLE_EXECUTOR_ADDRESS 1000000000000000000 --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Emergency ETH (0.002 ETH)
cast send --value 0.002ether $BUNDLE_EXECUTOR_ADDRESS --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Emergency CCIP-BnM
cast send $CCIP_BNM_ADDRESS "drip(address)" $BUNDLE_EXECUTOR_ADDRESS --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

## ✅ Funding Checklist

### Pre-Execution Checklist
- [ ] BundleExecutor has >= 0.005 ETH for gas
- [ ] BundleExecutor has >= 1.0 WETH for arbitrage
- [ ] BundleExecutor has >= 0.05 LINK for CCIP fees
- [ ] RemoteExecutor has >= 0.003 ETH for gas
- [ ] Liquidity pools are set up on both chains
- [ ] Circular dependencies are resolved

### Post-Execution Monitoring
- [ ] Check CCIP message on CCIP Explorer
- [ ] Verify balance changes are as expected
- [ ] Monitor RemoteExecutor for received tokens
- [ ] Top up balances if needed for next execution

This comprehensive funding guide ensures you never miss any funding requirements and can quickly resolve any funding issues that arise during arbitrage execution! 🚀
 