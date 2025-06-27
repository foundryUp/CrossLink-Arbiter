# Complete Deployment Guide - Circular Dependency Fix

This guide documents the complete deployment process for the Chainlink cross-chain arbitrage system with the circular dependency fix.

## Overview

**Problem Solved**: The original system had a circular dependency where BundleExecutor needed RemoteExecutor's address in its constructor, but RemoteExecutor needed BundleExecutor's address in its constructor.

**Solution Implemented**: 
- Deploy both contracts without each other's addresses
- Add one-time setter functions that can only be called by the owner
- Use setter functions to establish the relationship after both contracts are deployed

## Pre-Deployment Setup

### Environment Variables
```bash
export PRIVATE_KEY=0x9971812261ecfc8d83860eaceff14ab42748678da818e0ab8a586f6dde6adb2d
export ETHEREUM_SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/xiJw6cj_7U8PXLSncrSON78PWDXP4Dkl
export ARBITRUM_SEPOLIA_RPC_URL=https://arb-sepolia.g.alchemy.com/v2/xiJw6cj_7U8PXLSncrSON78PWDXP4Dkl
export FUNCTIONS_CONSUMER_ADDRESS=0x59c6AC86b75Caf8FC79782F79C85B8588211b6C2
export TREASURY_ADDRESS=0x28ea4eF61ac4cca3ed6A64dBb5b2D4be1aDC9814
```

### Additional Environment Variables for Testing
```bash
export BUNDLE_EXECUTOR_ADDRESS=0xB20412c4403277A6dD64e0D0dCa19F81b5412cBA
export REMOTE_EXECUTOR_ADDRESS=0x45ee7AA56775aB9385105393458FC4e56b4B578c
export WETH_ADDRESS=0xe95595f0BE77d6CF079795Ed63942933E9a6bf7b
export CCIP_BNM_ADDRESS=0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05
export ROUTER_ADDRESS=0x91a79cbF7e363FB38CfF04AdF031736C5914cd68
export LINK_ADDRESS=0x779877A7B0D9E8603169DdbD7836e478b4624789
```

## Step 1: Deploy Ethereum Contracts

### Command
```bash
forge script script/DeployEthereumContracts.s.sol \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

### Results
- **BundleExecutor**: `0xB20412c4403277A6dD64e0D0dCa19F81b5412cBA`
- **Mock WETH**: `0xe95595f0BE77d6CF079795Ed63942933E9a6bf7b`
- **Uniswap Router**: `0x91a79cbF7e363FB38CfF04AdF031736C5914cd68`
- **WETH/CCIP-BnM Pair**: `0xd7471664f91C43c5c3ed2B06734b4a392D94Fe16`
- **PlanStore** (existing): `0x1177D6F59e9877D6477743C6961988D86ee78174`

### Gas Cost
- **Total**: ~0.00001 ETH
- **Status**: ✅ All contracts verified on Sourcify

## Step 2: Deploy Arbitrum Contracts

### Command
```bash
forge script script/DeployArbitrumContracts.s.sol \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

### Results
- **RemoteExecutor**: `0x45ee7AA56775aB9385105393458FC4e56b4B578c`
- **Mock WETH**: `0x21ADF7b3F3AeA141E0b8544bF9de7e1e0CA21578`
- **Uniswap Router**: `0x35B9ff20240eb9B514150AE21D38F1596bf33355`
- **WETH/CCIP-BnM Pair**: `0xAc6D3a904c37c4B75F1823d1B0238d6d48D8bfB3`

### Gas Cost
- **Total**: ~0.0009 ETH
- **Status**: ✅ All contracts verified on Sourcify

## Step 3: Fix Circular Dependencies

### 3.1 Set RemoteExecutor in BundleExecutor (Ethereum)

```bash
forge script script/SetCircularAddresses.s.sol:SetCircularAddresses \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL \
  --broadcast \
  -vvvv
```

**Result**: ✅ Transaction hash: `0x5f2cb8facb79be75a7939cd806d2a8f2efff90f86a282dbaaa33b2c2faaf3316`

### 3.2 Set BundleExecutor in RemoteExecutor (Arbitrum)

```bash
forge script script/SetCircularAddresses.s.sol:SetAuthorizedSender \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL \
  --broadcast \
  -vvvv
```

**Result**: ✅ Transaction hash: `0x2bcc5049aa43429425914a5fb3bec195619e7a03893f432f6aa665146e72a60d`

### Gas Cost
- **Total**: ~0.000005 ETH (both transactions)

## Step 4: Complete Contract Funding

### 4.1 Initial BundleExecutor Funding (Ethereum)

#### Send ETH for gas costs
```bash
cast send --value 0.005ether $BUNDLE_EXECUTOR_ADDRESS \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```
**Result**: ✅ Transaction: `0x30da49ee73da92cff456cd0963966eb6eeb89fc6e9dba664dbcdb822f5f48c6c`

#### Initial WETH minting (0.5 WETH)
```bash
cast send $WETH_ADDRESS "mint(address,uint256)" \
  $BUNDLE_EXECUTOR_ADDRESS 500000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```
**Result**: ✅ Transaction: `0x80f6e4c492e66b9b50d2dd5247793f38de9f53e048ac42791927f5e061612c68`

#### Initial LINK tokens (0.05 LINK)
```bash
cast send $LINK_ADDRESS "transfer(address,uint256)" \
  $BUNDLE_EXECUTOR_ADDRESS 50000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```
**Result**: ✅ Transaction: `0xe688fc104cfc3b460cbf5931b08f8f71279da01e0f5a0ccf7f79dc2cf1e67b4a`

### 4.2 Fund RemoteExecutor (Arbitrum)

```bash
cast send --value 0.003ether $REMOTE_EXECUTOR_ADDRESS \
  --private-key $PRIVATE_KEY \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```
**Result**: ✅ Transaction: `0x90e95e149e494b8d65ede3df95253a47550c35d4cc6743b9af6862e602d6c2f4`

### 4.3 Emergency Funding (Required for Execution)

#### Additional WETH minting (1.5 WETH more)
```bash
# Add 1.5 WETH to meet minimum 1 WETH requirement
cast send $WETH_ADDRESS "mint(address,uint256)" \
  $BUNDLE_EXECUTOR_ADDRESS 1500000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```
**Result**: ✅ Transaction: `0x802fa89c9717093ced8c9df3c370b75103611b05e664428430def6aac43c953d`

#### Additional LINK tokens (0.05 LINK more)
```bash
# Add 0.05 LINK for sufficient CCIP fees (~0.044 LINK needed)
cast send $LINK_ADDRESS "transfer(address,uint256)" \
  $BUNDLE_EXECUTOR_ADDRESS 50000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```
**Result**: ✅ Transaction: `0x6022897cc762b2e8b7eefa84e5639bdf6f32705a9dcfc5c4328b0112a8de7b6a`

### 4.4 CCIP-BnM Token Management

#### Get CCIP-BnM from faucet (if needed)
```bash
# Ethereum Sepolia CCIP-BnM faucet
cast send $CCIP_BNM_ADDRESS "drip(address)" \
  $BUNDLE_EXECUTOR_ADDRESS \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Arbitrum Sepolia CCIP-BnM faucet  
cast send 0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D "drip(address)" \
  $REMOTE_EXECUTOR_ADDRESS \
  --private-key $PRIVATE_KEY \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

#### Transfer CCIP-BnM to BundleExecutor (if you have balance)
```bash
cast send $CCIP_BNM_ADDRESS "transfer(address,uint256)" \
  $BUNDLE_EXECUTOR_ADDRESS 1000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

### Total Funding Summary
- **ETH Funding**: 0.008 ETH (0.005 + 0.003)
- **WETH Minted**: 2.0 WETH total (0.5 + 1.5)
- **LINK Transferred**: 0.1 LINK total (0.05 + 0.05)
- **Status**: ✅ All funding successful

## Step 5: Setup Liquidity

### 5.1 Ethereum Sepolia Liquidity

```bash
forge script script/SetupLiquidity.s.sol \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL \
  --broadcast \
  --private-key $PRIVATE_KEY
```
**Result**: ✅ Liquidity added successfully

### 5.2 Arbitrum Sepolia Liquidity

```bash
# Set Arbitrum environment variables
export WETH_ADDRESS=0x21ADF7b3F3AeA141E0b8544bF9de7e1e0CA21578
export CCIP_BNM_ADDRESS=0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D
export ROUTER_ADDRESS=0x35B9ff20240eb9B514150AE21D38F1596bf33355

forge script script/SetupLiquidity.s.sol \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL \
  --broadcast \
  --private-key $PRIVATE_KEY

# Reset Ethereum environment variables
export WETH_ADDRESS=0xe95595f0BE77d6CF079795Ed63942933E9a6bf7b
export CCIP_BNM_ADDRESS=0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05
export ROUTER_ADDRESS=0x91a79cbF7e363FB38CfF04AdF031736C5914cd68
```
**Result**: ✅ Liquidity added successfully

## Step 6: Complete Balance Verification

### 6.1 Check All BundleExecutor Balances

#### ETH Balance
```bash
cast balance $BUNDLE_EXECUTOR_ADDRESS --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```
**Expected**: ~0.005 ETH

#### WETH Balance  
```bash
cast call $WETH_ADDRESS "balanceOf(address)" \
  $BUNDLE_EXECUTOR_ADDRESS \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```
**Expected**: 1600000000000000000 (1.6 WETH after funding)

#### LINK Balance
```bash
cast call $LINK_ADDRESS "balanceOf(address)" \
  $BUNDLE_EXECUTOR_ADDRESS \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```
**Expected**: 100000000000000000 (0.1 LINK total)

#### CCIP-BnM Balance
```bash
cast call $CCIP_BNM_ADDRESS "balanceOf(address)" \
  $BUNDLE_EXECUTOR_ADDRESS \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```
**Expected**: Variable (depends on faucet/transfers)

### 6.2 Check RemoteExecutor Balances

#### ETH Balance (Arbitrum)
```bash
cast balance $REMOTE_EXECUTOR_ADDRESS --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```
**Expected**: ~0.003 ETH

#### WETH Balance (Arbitrum)
```bash
cast call 0x21ADF7b3F3AeA141E0b8544bF9de7e1e0CA21578 "balanceOf(address)" \
  $REMOTE_EXECUTOR_ADDRESS \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

#### CCIP-BnM Balance (Arbitrum)
```bash
cast call 0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D "balanceOf(address)" \
  $REMOTE_EXECUTOR_ADDRESS \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

### 6.3 Circular Dependency Verification

#### Verify BundleExecutor knows RemoteExecutor
```bash
cast call $BUNDLE_EXECUTOR_ADDRESS "remoteExecutor()" \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```
**Expected Result**: `0x00000000000000000000000045ee7aa56775ab9385105393458fc4e56b4b578c` ✅

#### Verify RemoteExecutor knows BundleExecutor
```bash
cast call $REMOTE_EXECUTOR_ADDRESS "authorizedSender()" \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```
**Expected Result**: `0x000000000000000000000000b20412c4403277a6dd64e0d0dca19f81b5412cba` ✅

#### Verify setter flags are properly set
```bash
# Check BundleExecutor setter flag
cast call $BUNDLE_EXECUTOR_ADDRESS "remoteExecutorSet()" \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Check RemoteExecutor setter flag  
cast call $REMOTE_EXECUTOR_ADDRESS "authorizedSenderSet()" \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```
**Expected Result**: Both return `true` ✅

## Step 7: Testing and Execution

### 7.1 Plan and Automation Status Checks

#### Check if plan exists and should execute
```bash
cast call 0x1177D6F59e9877D6477743C6961988D86ee78174 "shouldExecute()" \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

#### Check automation upkeep conditions
```bash
cast call $BUNDLE_EXECUTOR_ADDRESS "checkUpkeep(bytes)" 0x \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

#### Store test plan via Functions Consumer
```bash
cast send $FUNCTIONS_CONSUMER_ADDRESS "storeTestPlan()" \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

### 7.2 Execute Test Arbitrage

#### Manual execution with CCIP tracking
```bash
forge script script/ExecuteAndGetCCIP.s.sol \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL \
  --broadcast \
  --private-key $PRIVATE_KEY
```

### 7.3 CCIP Message Tracking

#### Get full transaction receipt
```bash
# Replace <tx_hash> with actual transaction hash
cast receipt <tx_hash> --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

#### Extract CCIP-specific events
```bash
# Extract CCIP Router events
cast receipt <tx_hash> --rpc-url $ETHEREUM_SEPOLIA_RPC_URL --format json | jq '.logs[] | select(.address == "0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59")'

# Look for ArbitrageExecuted event with CCIP Message ID
cast receipt <tx_hash> --rpc-url $ETHEREUM_SEPOLIA_RPC_URL --format json | jq '.logs[] | select(.address == "'$BUNDLE_EXECUTOR_ADDRESS'")'
```

## Step 8: Emergency Funding Commands

### 8.1 Emergency LINK Top-up

#### Check current LINK balance
```bash
cast call $LINK_ADDRESS "balanceOf(address)" \
  $BUNDLE_EXECUTOR_ADDRESS \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

#### Add more LINK if CCIP fails
```bash
# Send additional 0.1 LINK if needed
cast send $LINK_ADDRESS "transfer(address,uint256)" \
  $BUNDLE_EXECUTOR_ADDRESS 100000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

### 8.2 Emergency WETH Top-up

#### Check current WETH balance
```bash
cast call $WETH_ADDRESS "balanceOf(address)" \
  $BUNDLE_EXECUTOR_ADDRESS \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

#### Mint additional WETH if needed
```bash
# Mint additional 1 WETH if needed
cast send $WETH_ADDRESS "mint(address,uint256)" \
  $BUNDLE_EXECUTOR_ADDRESS 1000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

### 8.3 Emergency CCIP-BnM Top-up

#### Check current CCIP-BnM balance
```bash
cast call $CCIP_BNM_ADDRESS "balanceOf(address)" \
  $BUNDLE_EXECUTOR_ADDRESS \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

#### Get CCIP-BnM from faucet
```bash
cast send $CCIP_BNM_ADDRESS "drip(address)" \
  $BUNDLE_EXECUTOR_ADDRESS \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

#### Transfer CCIP-BnM from your balance
```bash
cast send $CCIP_BNM_ADDRESS "transfer(address,uint256)" \
  $BUNDLE_EXECUTOR_ADDRESS 2000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

### 8.4 Emergency ETH Top-up

#### Add more ETH for gas if needed
```bash
cast send --value 0.002ether $BUNDLE_EXECUTOR_ADDRESS \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

cast send --value 0.002ether $REMOTE_EXECUTOR_ADDRESS \
  --private-key $PRIVATE_KEY \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

## Step 9: Troubleshooting Commands

### 9.1 Check Gas Prices
```bash
# Check current gas price on Ethereum
cast gas-price --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Check if it's under the 50 gwei limit (50000000000)
cast --to-wei 50 gwei
```

### 9.2 Check Pool Liquidity
```bash
# Check WETH/CCIP-BnM pair reserves on Ethereum
cast call 0xd7471664f91C43c5c3ed2B06734b4a392D94Fe16 "getReserves()" \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Check WETH/CCIP-BnM pair reserves on Arbitrum  
cast call 0xAc6D3a904c37c4B75F1823d1B0238d6d48D8bfB3 "getReserves()" \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

### 9.3 Test Individual Contract Functions

#### Test swap on Ethereum
```bash
cast send $BUNDLE_EXECUTOR_ADDRESS "testSwap()" \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

#### Test remote execution trigger
```bash
cast send $BUNDLE_EXECUTOR_ADDRESS "performUpkeep(bytes)" 0x \
  --private-key $PRIVATE_KEY \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

### 9.4 Monitor CCIP Messages

#### Check CCIP Explorer
- Visit: https://ccip.chain.link/
- Search by transaction hash or message ID
- Filter by source chain: Ethereum Sepolia
- Filter by destination chain: Arbitrum Sepolia

#### Check message status via contract (if implemented)
```bash
cast call $BUNDLE_EXECUTOR_ADDRESS "getLastCcipMessageId()" \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

## Final Contract Addresses

### Ethereum Sepolia
| Contract | Address | Description |
|----------|---------|-------------|
| **BundleExecutor** | `0xB20412c4403277A6dD64e0D0dCa19F81b5412cBA` | Main arbitrage executor |
| **PlanStore** | `0x1177D6F59e9877D6477743C6961988D86ee78174` | Stores execution plans |
| **Mock WETH** | `0xe95595f0BE77d6CF079795Ed63942933E9a6bf7b` | Wrapped ETH for testing |
| **WETH/CCIP-BnM Pair** | `0xd7471664f91C43c5c3ed2B06734b4a392D94Fe16` | DEX liquidity pool |
| **Uniswap Router** | `0x91a79cbF7e363FB38CfF04AdF031736C5914cd68` | DEX router |
| **CCIP-BnM Token** | `0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05` | Cross-chain token |
| **LINK Token** | `0x779877A7B0D9E8603169DdbD7836e478b4624789` | For CCIP fees |

### Arbitrum Sepolia
| Contract | Address | Description |
|----------|---------|-------------|
| **RemoteExecutor** | `0x45ee7AA56775aB9385105393458FC4e56b4B578c` | Remote arbitrage executor |
| **Mock WETH** | `0x21ADF7b3F3AeA141E0b8544bF9de7e1e0CA21578` | Wrapped ETH for testing |
| **WETH/CCIP-BnM Pair** | `0xAc6D3a904c37c4B75F1823d1B0238d6d48D8bfB3` | DEX liquidity pool |
| **Uniswap Router** | `0x35B9ff20240eb9B514150AE21D38F1596bf33355` | DEX router |
| **CCIP-BnM Token** | `0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D` | Cross-chain token |

### Chainlink Infrastructure
| Service | Address | Description |
|---------|---------|-------------|
| **CCIP Router (Ethereum)** | `0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59` | CCIP message router |
| **CCIP Router (Arbitrum)** | `0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165` | CCIP message router |
| **Functions Consumer** | `0x2eEbcC4807A0a8C95610E764369D0eeCEC5a655f` | Chainlink Functions |

## Latest Successful Test Results

### Most Recent Successful Execution
- **✅ Transaction Hash**: `0x3cdb00c162fb2d4538e669cad06fdc964b8d1515d877e8c54c71ffceaf031ed8`
- **✅ CCIP Message ID**: `0xf68b08b649d0d5ffe83770d2ae8339485c53ed7bbbc51a0928ff99a346583c27`
- **✅ Block Number**: 8,600,069
- **✅ Gas Used**: 389,464
- **✅ Destination**: Arbitrum Sepolia RemoteExecutor
- **✅ Status**: SUCCESS - Real addresses, no more dummy addresses!

### Execution Details
- **WETH Input**: 1.0 WETH
- **CCIP-BnM Output**: 0.07557 CCIP-BnM (sent cross-chain)
- **LINK Fee**: 0.044 LINK
- **Balance Changes**:
  - WETH: 1.6 → 0.6 WETH ✅
  - CCIP-BnM: 0 → 0 (sent to Arbitrum) ✅
  - LINK: 0.1 → 0.0117 LINK ✅

## Cost Summary

| Category | Amount | Status |
|----------|--------|--------|
| **Initial ETH Funding** | 0.008 ETH | ✅ |
| **Gas Costs (Deployment)** | ~0.001 ETH | ✅ |
| **Emergency Funding** | ~0.002 ETH | ✅ |
| **Total** | ~0.011 ETH | ✅ **Efficient deployment!** |

## Architecture Benefits

### ✅ Circular Dependency Fixed
- **Before**: Hardcoded dummy addresses in constructors
- **After**: Clean deployment with one-time setter functions

### 🔒 Security Improvements
- One-time setter functions prevent address changes after setup
- Owner-only access control on all setter functions
- No dummy addresses in production contracts

### 🚀 Deployment Benefits
- Flexible deployment process
- Easier testing and redeployment
- Clean contract architecture
- Better maintainability

## Next Steps

1. ✅ **Contracts Deployed** - All contracts successfully deployed and verified
2. ✅ **Circular Dependencies Resolved** - Both contracts know each other
3. ✅ **Contracts Funded** - Sufficient balances for operations
4. ✅ **Liquidity Added** - Pools have liquidity for arbitrage
5. ✅ **Manual Testing Complete** - Arbitrage execution confirmed working with CCIP tracking
6. 🔄 **Automation Setup** - Register new Chainlink Automation upkeep

## Quick Reference Commands

### Daily Operations
```bash
# Check system status
cast call 0x1177D6F59e9877D6477743C6961988D86ee78174 "shouldExecute()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Execute arbitrage manually with CCIP tracking
forge script script/ExecuteAndGetCCIP.s.sol --rpc-url $ETHEREUM_SEPOLIA_RPC_URL --broadcast --private-key $PRIVATE_KEY

# Check all balances quickly
cast balance $BUNDLE_EXECUTOR_ADDRESS --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast call $WETH_ADDRESS "balanceOf(address)" $BUNDLE_EXECUTOR_ADDRESS --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
cast call $LINK_ADDRESS "balanceOf(address)" $BUNDLE_EXECUTOR_ADDRESS --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

### Emergency Commands
```bash
# Quick LINK funding for CCIP fees
cast send $LINK_ADDRESS "transfer(address,uint256)" $BUNDLE_EXECUTOR_ADDRESS 100000000000000000 --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Quick WETH funding for arbitrage
cast send $WETH_ADDRESS "mint(address,uint256)" $BUNDLE_EXECUTOR_ADDRESS 1000000000000000000 --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Store fresh test plan
cast send $FUNCTIONS_CONSUMER_ADDRESS "storeTestPlan()" --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

## Troubleshooting

### Common Issues and Solutions

1. **"RemoteExecutorNotSet" error**
   ```bash
   forge script script/SetCircularAddresses.s.sol:SetCircularAddresses --rpc-url $ETHEREUM_SEPOLIA_RPC_URL --broadcast -vvvv
   ```

2. **"No valid plan" error**
   ```bash
   cast send $FUNCTIONS_CONSUMER_ADDRESS "storeTestPlan()" --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
   ```

3. **"CCIPSendFailed" error (insufficient LINK)**
   ```bash
   # Check LINK balance and top up
   cast call $LINK_ADDRESS "balanceOf(address)" $BUNDLE_EXECUTOR_ADDRESS --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
   cast send $LINK_ADDRESS "transfer(address,uint256)" $BUNDLE_EXECUTOR_ADDRESS 100000000000000000 --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
   ```

4. **"Insufficient WETH balance" error**
   ```bash
   # Check WETH balance and mint more
   cast call $WETH_ADDRESS "balanceOf(address)" $BUNDLE_EXECUTOR_ADDRESS --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
   cast send $WETH_ADDRESS "mint(address,uint256)" $BUNDLE_EXECUTOR_ADDRESS 1000000000000000000 --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
   ```

5. **Gas price too high**
   ```bash
   # Wait for lower gas prices or adjust maxGasPrice in BundleExecutor
   cast gas-price --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
   ```

6. **Transaction receipt analysis**
   ```bash
   # Get full receipt with CCIP details
   cast receipt <transaction_hash> --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
   ```

This deployment successfully resolves the circular dependency issue and provides a robust, secure foundation for the cross-chain arbitrage system with comprehensive monitoring, debugging capabilities, and complete CCIP message tracking.
 