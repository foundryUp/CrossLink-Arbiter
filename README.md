# ⚡ **CrossLink Arbitor** 
## *Autonomous Cross-Chain Arbitrage Protocol*

[![Built with Chainlink](https://img.shields.io/badge/Built%20with-Chainlink-375BD2.svg)](https://chain.link/)
[![Powered by AI](https://img.shields.io/badge/Powered%20by-Amazon%20Bedrock-FF9900.svg)](https://aws.amazon.com/bedrock/)
[![Cross-Chain](https://img.shields.io/badge/Cross--Chain-CCIP-00D4FF.svg)](https://chain.link/cross-chain)
[![Status](https://img.shields.io/badge/Status-Live%20on%20Testnet-00FF00.svg)](https://sepolia.etherscan.io/)

> 🏆 **Hackathon Project** | Fully autonomous cross-chain arbitrage system leveraging the complete Chainlink ecosystem + AI

---

## 🎯 **What is CrossLink Arbitor?**

CrossLink Arbitor is a **fully autonomous arbitrage protocol** that:
- 🔍 **Continuously monitors** price differences across multiple blockchains
- 🧠 **Uses AI** (Amazon Bedrock) to make intelligent trading decisions  
- ⚡ **Executes trades** automatically when profitable opportunities arise
- 🌉 **Operates cross-chain** using Chainlink CCIP for seamless asset transfers
- 💰 **Generates profit** by exploiting temporary price inefficiencies

**No human intervention required** - the system runs 24/7, making split-second decisions based on real-time market data and AI analysis.

---

## 🔗 **Chainlink Integration Files**

### **Core Chainlink Components**
| Service | Files | Purpose |
|---------|-------|---------|
| **Chainlink Functions** | [`ArbitrageFunctionsConsumer.sol`](ccip-starter/src/ArbitrageFunctionsConsumer.sol) | Off-chain AI computation and market analysis |
| **Chainlink Automation** | [`BundleExecutor.sol`](ccip-starter/src/BundleExecutor.sol) | Autonomous execution when conditions are met |
| **Chainlink CCIP** | [`BundleExecutor.sol`](ccip-starter/src/BundleExecutor.sol), [`RemoteExecutor.sol`](ccip-starter/src/RemoteExecutor.sol) | Cross-chain asset transfers and messaging |

### **Supporting Infrastructure**
| Component | Files | Integration |
|-----------|-------|-------------|
| **Plan Storage** | [`PlanStore.sol`](ccip-starter/src/PlanStore.sol) | Interfaces with Functions Consumer and Automation |
| **API Server** | [`server.js`](chainlink-functions/server.js) | Called by Chainlink Functions for AI analysis |
| **Test Suite** | [`ArbFlow.t.sol`](ccip-starter/test/fork/ArbFlow.t.sol) | CCIP Local Simulator integration |

---

## 🏗️ **System Architecture**

> 📖 **[View Complete Technical Architecture](docs/ARCHITECTURE.md)** - Detailed system design, flow diagrams, and component specifications


### **Technical Stack**
- **Smart Contracts**: Solidity 0.8.24 + Foundry
- **Cross-Chain**: Chainlink CCIP (Ethereum ↔ Arbitrum)
- **Automation**: Chainlink Automation (Upkeep system)
- **Off-Chain Compute**: Chainlink Functions + Node.js API
- **AI Engine**: Amazon Bedrock (Titan Text Express)
- **DEX Integration**: Mock Uniswap V2 (for testing)
- **Cloud Infrastructure**: Render.com hosting servers
- **Testing**: Fork testing with CCIP simulation

---

## 🔄 **How It Works**

### **1. 🔍 Market Surveillance**
- Monitors WETH/CCIP-BnM pools on Ethereum Sepolia and Arbitrum Sepolia
- Fetches real-time reserves via RPC calls every 5 minutes
- Calculates price spreads and identifies arbitrage opportunities

### **2. 🧠 AI-Powered Decision Making**
- Sends market data to Amazon Bedrock for intelligent analysis
- AI considers: price spreads, gas costs, market volatility, profit potential
- Falls back to rule-based logic if AI is unavailable
- Returns structured decisions: execute/skip, amount, thresholds

### **3. ⚡ Autonomous Execution**
- Chainlink Automation triggers when profitable conditions are met
- Validates: sufficient balance, acceptable gas prices, plan validity
- Executes multi-step arbitrage automatically

### **4. 🌉 Cross-Chain Coordination**
- **Step 1**: Swap WETH → CCIP-BnM on Ethereum
- **Step 2**: Send CCIP-BnM + instructions to Arbitrum via CCIP
- **Step 3**: Receive tokens and swap CCIP-BnM → WETH on Arbitrum  
- **Step 4**: Send profit to treasury, complete the cycle

---

## 📊 **Live System Status**

### **🌐 Deployed Contracts**

#### **Ethereum Sepolia**
| Contract | Address | Purpose |
|----------|---------|---------|
| **Bundle Executor** | [`0xB20412c4403277A6dD64e0D0dCa19F81b5412cBA`](https://sepolia.etherscan.io/address/0xB20412c4403277A6dD64e0D0dCa19F81b5412cBA) | Main arbitrage executor + CCIP sender |
| **Functions Consumer** | [`0x59c6AC86b75Caf8FC79782F79C85B8588211b6C2`](https://sepolia.etherscan.io/address/0x59c6AC86b75Caf8FC79782F79C85B8588211b6C2) | Chainlink Functions interface |
| **Plan Store** | [`0x1177D6F59e9877D6477743C6961988D86ee78174`](https://sepolia.etherscan.io/address/0x1177D6F59e9877D6477743C6961988D86ee78174) | Stores AI-generated execution plans |
| **Mock WETH** | [`0xe95595f0BE77d6CF079795Ed63942933E9a6bf7b`](https://sepolia.etherscan.io/address/0xe95595f0BE77d6CF079795Ed63942933E9a6bf7b) | Wrapped ETH for testing |
| **WETH/CCIP-BnM Pair** | [`0xd7471664f91C43c5c3ed2B06734b4a392D94Fe16`](https://sepolia.etherscan.io/address/0xd7471664f91C43c5c3ed2B06734b4a392D94Fe16) | DEX liquidity pool |
| **Uniswap Router** | [`0x91a79cbF7e363FB38CfF04AdF031736C5914cd68`](https://sepolia.etherscan.io/address/0x91a79cbF7e363FB38CfF04AdF031736C5914cd68) | DEX router for swaps |
| **CCIP-BnM Token** | [`0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05`](https://sepolia.etherscan.io/address/0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05) | Cross-chain test token |

#### **Arbitrum Sepolia**
| Contract | Address | Purpose |
|----------|---------|---------|
| **Remote Executor** | [`0x45ee7AA56775aB9385105393458FC4e56b4B578c`](https://arbiscan.io/address/0x45ee7AA56775aB9385105393458FC4e56b4B578c) | CCIP receiver + final execution |
| **Mock WETH** | [`0x21ADF7b3F3AeA141E0b8544bF9de7e1e0CA21578`](https://arbiscan.io/address/0x21ADF7b3F3AeA141E0b8544bF9de7e1e0CA21578) | Wrapped ETH for testing |
| **WETH/CCIP-BnM Pair** | [`0xAc6D3a904c37c4B75F1823d1B0238d6d48D8bfB3`](https://arbiscan.io/address/0xAc6D3a904c37c4B75F1823d1B0238d6d48D8bfB3) | DEX liquidity pool |
| **Uniswap Router** | [`0x35B9ff20240eb9B514150AE21D38F1596bf33355`](https://arbiscan.io/address/0x35B9ff20240eb9B514150AE21D38F1596bf33355) | DEX router for swaps |
| **CCIP-BnM Token** | [`0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D`](https://arbiscan.io/address/0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D) | Cross-chain test token |

#### **API Endpoint**
- **Live API**: [`https://chainlink-hackathon.onrender.com`](https://chainlink-hackathon.onrender.com)
- **Health Check**: [`/api/analyze`](https://chainlink-hackathon.onrender.com/api/analyze?ethPair=0xd7471664f91C43c5c3ed2B06734b4a392D94Fe16&arbPair=0xAc6D3a904c37c4B75F1823d1B0238d6d48D8bfB3)


---

## 🚀 **Deploy Your Own CrossLink Arbitor**

> 📖 **[Complete Deployment Guide](docs/COMPLETE-DEPLOYMENT-GUIDE.md)** - Step-by-step instructions for deployment, funding, testing, and troubleshooting
---

## 📚 **Documentation Links**

- 📖 **[Technical Architecture](docs/ARCHITECTURE.md)** - Complete system design, flow diagrams, and components
- 🚀 **[Complete Deployment Guide](docs/COMPLETE-DEPLOYMENT-GUIDE.md)** - Step-by-step deployment, funding, testing, and troubleshooting
- 🔧 **[Deployment Details](docs/DEPLOYMENT-DETAILS.md)** - All contract addresses and live system info
- 🎯 **[Hackathon Pitch](docs/HACKATHON-PITCH.md)** - Presentation materials

---

## 🏆 **Key Features & Innovations**

### **🧠 AI-Powered Trading**
- **Amazon Bedrock Integration**: Uses Titan Text Express for market analysis
- **Intelligent Decision Making**: Considers multiple factors beyond simple price differences
- **Adaptive Learning**: AI improves decisions based on market conditions
- **Fallback Resilience**: Rule-based backup ensures system never fails

### **⚡ Fully Autonomous Operation**
- **Zero Human Intervention**: Runs 24/7 without manual oversight
- **Chainlink Automation**: Reliable execution triggered by on-chain conditions
- **Self-Validating**: Built-in safety checks prevent unprofitable trades
- **Error Recovery**: Comprehensive error handling and retry logic

### **🌉 Seamless Cross-Chain Execution**  
- **CCIP Integration**: Native cross-chain asset transfers
- **Atomic Operations**: Ensures trade completion or full rollback
- **Multi-Chain Coordination**: Synchronizes actions across Ethereum and Arbitrum
- **Message Verification**: Cryptographic proof of cross-chain communications

### **🔒 Production-Ready Security**
- **Access Control**: Owner-only administrative functions
- **Circular Dependency Resolution**: Innovative deployment strategy
- **Reentrancy Protection**: Safe external contract interactions
- **Emergency Stops**: Circuit breakers for unexpected conditions

---

## 💡 **Business Model & Use Cases**

### **Revenue Streams**
1. **Arbitrage Profits**: Direct profit from price differences
2. **Protocol Fees**: Small percentage on successful trades  
3. **API Licensing**: Sell access to other protocols
4. **Strategy Consulting**: Custom arbitrage solutions

### **Use Cases**
- **Individual Traders**: Deploy personal arbitrage bots
- **DeFi Protocols**: Integrate automated arbitrage features
- **Market Makers**: Maintain price consistency across chains
- **Treasury Management**: Generate yield from cross-chain opportunities

---

## 🤝 **Contributing**

We welcome contributions! Please see our contributing guidelines:

1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit changes**: `git commit -m 'Add amazing feature'`
4. **Push to branch**: `git push origin feature/amazing-feature`
5. **Open Pull Request**

---

## 📞 **Support & Community**

### **🌐 Live Links**
- **Demo**: [https://chainlink-hackathon.onrender.com](https://chainlink-hackathon.onrender.com)
- **CCIP Explorer**: [https://ccip.chain.link/](https://ccip.chain.link/)

### **🔗 Social & Code**
- **GitHub**: [Repository](https://github.com/your-username/crosslink-arbitor)
- **Twitter**: [@CrossLinkArbitor](https://twitter.com/crosslinkarbitor) 
- **Discord**: [Join Community](https://discord.gg/crosslink)
- **Telegram**: [Discussion Group](https://t.me/crosslinkarbitor)

---

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

### ⚡ **CrossLink Arbitor** - *The Future of Autonomous Cross-Chain Trading*

**Built with ❤️ for the Chainlink Ecosystem**

[![Chainlink](https://img.shields.io/badge/Powered%20By-Chainlink-375BD2.svg?style=for-the-badge)](https://chain.link/)
[![AI](https://img.shields.io/badge/Enhanced%20By-Amazon%20Bedrock-FF9900.svg?style=for-the-badge)](https://aws.amazon.com/bedrock/)

</div> 
