# Cross-Chain Arbitrage Protocol - Deployment Guide

## Deployed Contract Addresses

### Ethereum Sepolia (Chain ID: 11155111)
| Contract | Address |
|----------|---------|
| **BundleExecutor** | `0xB20412c4403277A6dD64e0D0dCa19F81b5412cBA` |
| **PlanStore** | `0x1177D6F59e9877D6477743C6961988D86ee78174` |
| **Mock WETH** | `0xe95595f0BE77d6CF079795Ed63942933E9a6bf7b` |
| **WETH/CCIP-BnM Pair** | `0xd7471664f91C43c5c3ed2B06734b4a392D94Fe16` |
| **Uniswap Router** | `0x91a79cbF7e363FB38CfF04AdF031736C5914cd68` |
| **CCIP-BnM Token** | `0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05` |

### Arbitrum Sepolia (Chain ID: 421614)
| Contract | Address |
|----------|---------|
| **RemoteExecutor** | `0x45ee7AA56775aB9385105393458FC4e56b4B578c` |
| **Mock WETH** | `0x21ADF7b3F3AeA141E0b8544bF9de7e1e0CA21578` |
| **WETH/CCIP-BnM Pair** | `0xAc6D3a904c37c4B75F1823d1B0238d6d48D8bfB3` |
| **Uniswap Router** | `0x35B9ff20240eb9B514150AE21D38F1596bf33355` |
| **CCIP-BnM Token** | `0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D` |

## Configuration
- **Treasury**: `0x28ea4eF61ac4cca3ed6a64dBb5b2D4be1aDC9814`
- **Deployer**: `0xbb0235ADdc0d3C23bF3904Fc47EB6284328fFB5E`
- **Functions Consumer**: `0x2eEbcC4807A0a8C95610E764369D0eeCEC5a655f`

## Deployment Commands

### Environment Setup
```bash
export PRIVATE_KEY=0x9971812261ecfc8d83860eaceff14ab42748678da818e0ab8a586f6dde6adb2d
export TREASURY_ADDRESS=0x28ea4eF61ac4cca3ed6a64dBb5b2D4be1aDC9814
export ETHEREUM_SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/xiJw6cj_7U8PXLSncrSON78PWDXP4Dkl
export ARBITRUM_SEPOLIA_RPC_URL=https://arb-sepolia.g.alchemy.com/v2/xiJw6cj_7U8PXLSncrSON78PWDXP4Dkl
```

### Deploy Ethereum Contracts
```bash
export FUNCTIONS_CONSUMER_ADDRESS=0x2eEbcC4807A0a8C95610E764369D0eeCEC5a655f
forge script script/DeployEthereumContracts.s.sol --rpc-url $ETHEREUM_SEPOLIA_RPC_URL --broadcast --verify
```

### Deploy Arbitrum Contracts
```bash
export BUNDLE_EXECUTOR_ADDRESS=0xB20412c4403277A6dD64e0D0dCa19F81b5412cBA
forge script script/DeployArbitrumContracts.s.sol --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast --verify
```

### Set Circular Dependencies (New Fix!)
```bash
# Set RemoteExecutor in BundleExecutor (Ethereum)
export REMOTE_EXECUTOR_ADDRESS=0x45ee7AA56775aB9385105393458FC4e56b4B578c
forge script script/SetCircularAddresses.s.sol:SetCircularAddresses --rpc-url $ETHEREUM_SEPOLIA_RPC_URL --broadcast

# Set BundleExecutor in RemoteExecutor (Arbitrum) 
forge script script/SetCircularAddresses.s.sol:SetAuthorizedSender --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast
```

### Get Test Tokens
```bash
# Ethereum Sepolia
forge script script/Faucet.s.sol:Faucet \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL \
  --broadcast \
  --private-key $PRIVATE_KEY \
  --sig "run(uint8)" 0 \
  -vv

# Arbitrum Sepolia  
forge script script/Faucet.s.sol:Faucet \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL \
  --broadcast \
  --private-key $PRIVATE_KEY \
  --sig "run(uint8)" 2 \
  -vv
```

### Setup Liquidity
```bash
# Ethereum Sepolia
export WETH_ADDRESS=0xe95595f0BE77d6CF079795Ed63942933E9a6bf7b
export CCIP_BNM_ADDRESS=0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05
export ROUTER_ADDRESS=0x91a79cbF7e363FB38CfF04AdF031736C5914cd68

forge script script/SetupLiquidity.s.sol \
  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL \
  --broadcast \
  --private-key $PRIVATE_KEY \
  -vv

# Arbitrum Sepolia
export WETH_ADDRESS=0x21ADF7b3F3AeA141E0b8544bF9de7e1e0CA21578
export CCIP_BNM_ADDRESS=0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D
export ROUTER_ADDRESS=0x35B9ff20240eb9B514150AE21D38F1596bf33355

forge script script/SetupLiquidity.s.sol \
  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL \
  --broadcast \
  --private-key $PRIVATE_KEY \
  -vv
```

## Chainlink Functions Configuration

**Consumer**: `0x2eEbcC4807A0a8C95610E764369D0eeCEC5a655f`  
**Subscription ID**: `5056`  
**Code**: `chainlink-functions/arbitrage-functions.js`

### Required Arguments
```javascript
args = [
  "0xd7471664f91C43c5c3ed2B06734b4a392D94Fe16", // Ethereum WETH/CCIP-BnM pair
  "0xAc6D3a904c37c4B75F1823d1B0238d6d48D8bfB3", // Arbitrum WETH/CCIP-BnM pair  
  "0xe95595f0BE77d6CF079795Ed63942933E9a6bf7b", // Ethereum WETH token
  "0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05", // Ethereum CCIP-BnM token
  "0x21ADF7b3F3AeA141E0b8544bF9de7e1e0CA21578", // Arbitrum WETH token
  "0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D"  // Arbitrum CCIP-BnM token
]
```

### Required Secrets
```javascript
secrets = {
  anthropicApiKey: "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"
}
```

## Current Pool Status

| Chain | WETH Amount | CCIP-BnM Amount | Price (CCIP-BnM per WETH) |
|-------|-------------|-----------------|------------------------|
| **Ethereum** | 1.0 WETH | 40 CCIP-BnM | 40.000000 |
| **Arbitrum** | 0.8 WETH | 40 CCIP-BnM | 50.000000 |

**Arbitrage Opportunity**: 25% (2500 basis points)

## Architecture Flow

```
Chainlink Functions → PlanStore → Chainlink Automation → BundleExecutor → CCIP → RemoteExecutor
```

## Status: FULLY DEPLOYED
