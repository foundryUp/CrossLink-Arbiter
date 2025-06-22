# Tokens and Pools Architecture

## Token Strategy

| Token | Type | Cross-Chain | Purpose |
|-------|------|-------------|---------|
| **CCIP-BnM** | Real Chainlink testnet token | ✅ Yes | Cross-chain transfers |
| **WETH** | Mock deployed contract | ❌ No | Arbitrage trading |

## Why This Hybrid Approach?

**Real CCIP-BnM**:
- Native Chainlink testnet token
- Built-in CCIP support
- Free testnet faucet
- Real cross-chain transfers

**Mock WETH**:
- Real WETH doesn't exist on testnets
- Easy to mint for testing
- Controlled supply for predictable results

## Current Pool Setup

### Ethereum Sepolia
- **Pair**: `0xD43E97984d9faD6d41cb901b81b3403A1e7005Fb`
- **WETH**: `0xe95dd35Ef9dCafD0e570D378Fa04527c22A87911` (mock)
- **CCIP-BnM**: `0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05` (real)
- **Reserves**: 1.0 WETH ⟷ 40 CCIP-BnM
- **Price**: 40 CCIP-BnM per WETH

### Arbitrum Sepolia  
- **Pair**: `0x7DCA1D3AcAcdA7cDdCAD345FB1CDC6109787914F`
- **WETH**: `0x9BAd0F20eB62a2238c9849A7cE50FCafdE0E1481` (mock)
- **CCIP-BnM**: `0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D` (real)
- **Reserves**: 0.8 WETH ⟷ 40 CCIP-BnM  
- **Price**: 50 CCIP-BnM per WETH

**Arbitrage Opportunity**: 25% price difference

## Arbitrage Flow

```
1. Ethereum: Swap WETH → CCIP-BnM (lower price)
2. CCIP: Transfer CCIP-BnM to Arbitrum (real cross-chain)
3. Arbitrum: Swap CCIP-BnM → WETH (higher price)
4. Profit: More WETH received than spent
```

## Token Verification

### Check CCIP-BnM is Real
```bash
# Has drip function (faucet)
cast call 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05 "drip(address)" YOUR_ADDRESS --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

### Check WETH is Mock
```bash
# Has mint function (real WETH doesn't)
cast send 0xe95dd35Ef9dCafD0e570D378Fa04527c22A87911 "mint(address,uint256)" YOUR_ADDRESS 1000000000000000000 --rpc-url $ETHEREUM_SEPOLIA_RPC_URL
```

## Migration to Mainnet

To deploy on mainnet:
- Replace Mock WETH → Real WETH (`0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2`)
- Replace CCIP-BnM → Real USDC (CCIP-supported)
# Token and Pool Addresses

## Token Addresses

### Ethereum Sepolia (Chain ID: 11155111)

**Mock WETH (Wrapped Ethereum)**
- **Address**: `0xe95595f0BE77d6CF079795Ed63942933E9a6bf7b`
- **Type**: Mock ERC20 - can be minted freely
- **Decimals**: 18
- **Purpose**: Local arbitrage execution token

**CCIP-BnM (Cross-Chain Interoperability Protocol - Burn & Mint)**
- **Address**: `0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05`
- **Type**: Real Chainlink CCIP token
- **Decimals**: 18
- **Purpose**: Cross-chain token transfers

### Arbitrum Sepolia (Chain ID: 421614)

**Mock WETH (Wrapped Ethereum)**
- **Address**: `0x21ADF7b3F3AeA141E0b8544bF9de7e1e0CA21578`
- **Type**: Mock ERC20 - can be minted freely
- **Decimals**: 18
- **Purpose**: Arbitrage completion token

**CCIP-BnM (Cross-Chain Interoperability Protocol - Burn & Mint)**
- **Address**: `0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D`
- **Type**: Real Chainlink CCIP token
- **Decimals**: 18
- **Purpose**: Cross-chain token transfers

## Pool Addresses (Uniswap V2 Style)

### Ethereum Sepolia
- **Pair**: `0xd7471664f91C43c5c3ed2B06734b4a392D94Fe16`
- **WETH**: `0xe95595f0BE77d6CF079795Ed63942933E9a6bf7b` (mock)
- **CCIP-BnM**: `0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05` (real)
- **Router**: `0x91a79cbF7e363FB38CfF04AdF031736C5914cd68`

### Arbitrum Sepolia  
- **Pair**: `0xAc6D3a904c37c4B75F1823d1B0238d6d48D8bfB3`
- **WETH**: `0x21ADF7b3F3AeA141E0b8544bF9de7e1e0CA21578` (mock)
- **CCIP-BnM**: `0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D` (real)
- **Router**: `0x35B9ff20240eb9B514150AE21D38F1596bf33355`

## Getting Test Tokens

### CCIP-BnM (Cross-chain tokens)
```bash
# Ethereum Sepolia - Get CCIP-BnM tokens
cast call 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05 "drip(address)" YOUR_ADDRESS --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Arbitrum Sepolia - Get CCIP-BnM tokens
cast call 0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D "drip(address)" YOUR_ADDRESS --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

### Mock WETH (Local testing tokens)
```bash
# Ethereum Sepolia - Mint WETH
cast send 0xe95595f0BE77d6CF079795Ed63942933E9a6bf7b "mint(address,uint256)" YOUR_ADDRESS 1000000000000000000 --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

# Arbitrum Sepolia - Mint WETH  
cast send 0x21ADF7b3F3AeA141E0b8544bF9de7e1e0CA21578 "mint(address,uint256)" YOUR_ADDRESS 1000000000000000000 --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
```

## Important Notes

### For Production
- Replace Mock WETH → Real WETH (`0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2`)
- Replace Mock pools → Real Uniswap V2/V3 pools
- Test on testnets first, then deploy to mainnet

### Pool Mechanics
- **Reserves**: Check current liquidity with `getReserves()`
- **Prices**: Calculated as `reserve1/reserve0` ratio
- **Arbitrage**: Profit from price differences between chains

### CCIP Integration
- CCIP-BnM tokens can be transferred cross-chain
- Burn & Mint mechanism ensures 1:1 token ratio
- Real tokens work with Chainlink CCIP infrastructure

### New Deployment Benefits
- ✅ **Clean Addresses**: No more dummy/hardcoded addresses
- 🔒 **Secure Setup**: Circular dependencies properly resolved
- 🚀 **Fresh Start**: New contracts with improved architecture
- 💰 **Cost Efficient**: Total deployment under 0.001 ETH
