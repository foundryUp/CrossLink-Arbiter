# 🏗️ **CrossLink Arbitor - Technical Architecture**

## **System Overview**

CrossLink Arbitor represents a sophisticated autonomous cross-chain arbitrage system that leverages the complete Chainlink ecosystem. The system operates through multiple interconnected components across different execution environments.

---


## 🔄 **Execution Flow Architecture**

### **Phase 1: Market Analysis & Intelligence**

```mermaid
graph TB
    subgraph "Off-Chain Intelligence Layer"
        TIMER["⏰ 5-Minute Timer - Chainlink Automation"]
        FC["📞 Functions Consumer - ArbitrageFunctionsConsumer.sol"]
        API["🌐 CrossLink API - Express.js Server"]
        AI["🧠 Amazon Bedrock - Titan Text Express"]
    end
    
    subgraph "Data Sources"
        ETH_RPC["📡 Ethereum RPC - Pool Reserves"]
        ARB_RPC["📡 Arbitrum RPC - Pool Reserves"]
        GAS_ORACLE["⛽ Gas Price Oracle - Both Chains"]
    end
    
    TIMER -->|Trigger| FC
    FC -->|HTTP Request| API
    API -->|Parallel Fetch| ETH_RPC
    API -->|Parallel Fetch| ARB_RPC
    API -->|Fetch| GAS_ORACLE
    API -->|Market Data| AI
    AI -->|Decision| API
    API -->|CSV Response| FC
```

### **Phase 2: Plan Storage & Validation**

```mermaid
graph LR
    subgraph "On-Chain Storage"
        FC["Functions Consumer - Receives CSV Response"]
        PARSER["CSV Parser - String Processing"]
        PS["Plan Store - Structured Data"]
        VALIDATOR["Plan Validator - Timestamp & Expiry"]
    end
    
    FC --> PARSER
    PARSER --> PS
    PS --> VALIDATOR
    VALIDATOR -->|Valid Plan| AUTOMATION_TRIGGER
    VALIDATOR -->|Expired/Invalid| DISCARD
    
    AUTOMATION_TRIGGER["⚡ Trigger Automation"]
    DISCARD["🗑️ Plan Discarded"]
```

### **Phase 3: Automation & Execution**

```mermaid
graph TB
    subgraph "Chainlink Automation"
        AUTO["⏰ Automation Network - 30-second intervals"]
        CHECK["🔍 checkUpkeep() - Condition Validation"]
        PERFORM["⚙️ performUpkeep() - Execution Trigger"]
    end
    
    subgraph "Validation Logic"
        PLAN_CHECK["📋 Plan Exists & Valid?"]
        BALANCE_CHECK["💰 Sufficient WETH?"]
        GAS_CHECK["⛽ Gas Price OK?"]
        REMOTE_CHECK["🔗 Remote Executor Set?"]
    end
    
    AUTO --> CHECK
    CHECK --> PLAN_CHECK
    CHECK --> BALANCE_CHECK  
    CHECK --> GAS_CHECK
    CHECK --> REMOTE_CHECK
    
    PLAN_CHECK -->|All Pass| PERFORM
    BALANCE_CHECK -->|All Pass| PERFORM
    GAS_CHECK -->|All Pass| PERFORM
    REMOTE_CHECK -->|All Pass| PERFORM
    
    PERFORM --> EXECUTE["🚀 Execute Arbitrage"]
```

### **Phase 4: Cross-Chain Execution**

```mermaid
%%{init: {'theme':'dark'}}%%
sequenceDiagram
    participant BE as ⚙️ Bundle Executor
    participant UNIV2E as 🔄 Uniswap V2 (ETH)
    participant CCIP as 🌉 CCIP Network
    participant RE as 🎯 Remote Executor
    participant UNIV2A as 🔄 Uniswap V2 (ARB)
    participant TREASURY as 🏦 Treasury
    
    Note over BE,TREASURY: Cross-Chain Arbitrage Execution
    
    rect rgb(45, 45, 45)
        Note over BE,UNIV2E: Ethereum Sepolia - Source Chain
        BE->>+UNIV2E: 1. Swap WETH → CCIP-BnM
        UNIV2E->>UNIV2E: 2. Execute AMM Formula
        UNIV2E-->>-BE: 3. Return CCIP-BnM Amount
        
        BE->>BE: 4. Prepare CCIP Message
        Note right of BE: • Token: CCIP-BnM • Data: Amount + Deadline • Destination: Remote Executor
        
        BE->>+CCIP: 5. Send Cross-Chain Transfer
        CCIP-->>-BE: 6. Return Message ID
    end
    
    rect rgb(35, 35, 35)
        Note over CCIP,TREASURY: Cross-Chain Message Routing
        CCIP->>CCIP: 7. Validate Message
        CCIP->>CCIP: 8. Route to Arbitrum
        CCIP->>+RE: 9. Deliver Message + Tokens
    end
    
    rect rgb(50, 50, 50)
        Note over RE,TREASURY: Arbitrum Sepolia - Destination Chain
        RE->>RE: 10. Validate Sender & Chain
        RE->>+UNIV2A: 11. Swap CCIP-BnM → WETH
        UNIV2A->>UNIV2A: 12. Execute AMM Formula
        UNIV2A-->>-RE: 13. Return WETH Amount
        
        RE->>+TREASURY: 14. Transfer Profit
        TREASURY-->>-RE: 15. Confirm Receipt
        RE-->>-CCIP: 16. Execution Complete ✅
    end
```

---

## 🔗 **Complete Contract Flow Architecture**

### **High-Level System Overview with Contract Integration**

```mermaid
graph TB
    subgraph "Off-Chain Layer"
        API["CrossLink AI API<br/>Amazon Bedrock Analysis<br/>Market Data Processing<br/>Price Spread Calculation<br/>AI Decision Making"]
        FUNCTIONS["Chainlink Functions DON<br/>Decentralized Oracle Network<br/>HTTP Request Execution<br/>Response Validation"]
        CCIP_NET["Chainlink CCIP Network<br/>Cross-Chain Messaging<br/>Token Transfer Protocol<br/>Message Verification"]
        AUTOMATION["Chainlink Automation<br/>Upkeep Monitoring (30s intervals)<br/>Condition Validation<br/>Autonomous Execution"]
    end
    
    subgraph "Ethereum Sepolia - Source Chain"
        TIMER["Timer Trigger<br/>Every 5 Minutes"]
        AFC["ArbitrageFunctionsConsumer.sol<br/>sendRequest() every 5 min<br/>Calls Chainlink Functions<br/>Receives AI arbitrage plan<br/>Parses CSV response<br/>Auto-triggers plan storage"]
        PS["PlanStore.sol<br/>fulfillPlan() from Consumer<br/>Stores execution parameters<br/>Plan expiry: 5 minutes<br/>shouldExecute() validation<br/>Plan clearance after execution"]
        BE["BundleExecutor.sol<br/>checkUpkeep() monitors PlanStore<br/>Validates: balance, gas, plan validity<br/>performUpkeep() executes arbitrage<br/>Swaps WETH to CCIP-BnM<br/>Sends cross-chain message + tokens"]
        UNIV2_ETH["Uniswap V2 (ETH)<br/>WETH/CCIP-BnM Pool<br/>Source chain liquidity<br/>AMM swap execution"]
    end
    
    subgraph "Arbitrum Sepolia - Destination Chain"
        RE["RemoteExecutor.sol<br/>ccipReceive() handles messages<br/>Validates sender & chain<br/>Swaps CCIP-BnM to WETH<br/>Calculates & transfers profit<br/>Completes arbitrage cycle"]
        UNIV2_ARB["Uniswap V2 (ARB)<br/>WETH/CCIP-BnM Pool<br/>Destination chain liquidity<br/>Final swap execution"]
        TREASURY["Treasury Wallet<br/>Receives arbitrage profits<br/>Revenue accumulation<br/>Protocol treasury"]
    end
    
    TIMER -->|"Triggers every 5 min"| AFC
    AFC -->|"1. sendRequest() HTTP call"| FUNCTIONS
    FUNCTIONS -->|"2. Makes API call"| API
    API -->|"3. Returns AI decision CSV"| FUNCTIONS
    FUNCTIONS -->|"4. fulfillRequest() callback"| AFC
    AFC -->|"5. storeParsedPlan() auto-execution"| PS
    PS -->|"6. Plan available trigger"| AUTOMATION
    AUTOMATION -->|"7. checkUpkeep() every 30s"| BE
    BE -->|"8. performUpkeep() execution"| BE
    BE -->|"9. Swap WETH to CCIP-BnM"| UNIV2_ETH
    BE -->|"10. CCIP send (tokens + data)"| CCIP_NET
    CCIP_NET -->|"11. Cross-chain delivery"| RE
    RE -->|"12. Swap CCIP-BnM to WETH"| UNIV2_ARB
    RE -->|"13. Transfer profit"| TREASURY
    
    FUNCTIONS -.->|"Decentralized Compute"| AFC
    AUTOMATION -.->|"Autonomous Monitoring"| BE
    CCIP_NET -.->|"Secure Cross-Chain"| RE
```

### **Detailed Contract Flow & Responsibilities**

#### **⏰ Timing & Execution Cycle**
1. **Every 5 Minutes**: `ArbitrageFunctionsConsumer.sol` triggers `sendRequest()`
2. **Every 30 Seconds**: `BundleExecutor.sol` runs `checkUpkeep()` to monitor for new plans
3. **5 Minute Expiry**: Plans auto-expire to prevent stale executions
4. **Instant Execution**: When conditions are met, arbitrage executes immediately

#### **📋 Contract Responsibilities & Integration**

| Contract | Timing | Chainlink Service | Detailed Responsibilities |
|----------|--------|-------------------|---------------------------|
| **ArbitrageFunctionsConsumer.sol** | Every 5 min | Functions+ Time Based Automation | • `sendRequest()` calls API for AI analysis<br/>• `_fulfillRequest()` receives AI decision CSV<br/>• `storeParsedPlan()` auto-parses and stores plan<br/>• Manages Functions subscription and gas |
| **PlanStore.sol** | On-demand | - | • `fulfillPlan()` stores execution parameters from Consumer<br/>• `shouldExecute()` validates plan age (<5 min) and execute flag<br/>• `getCurrentPlan()` provides plan details to Automation<br/>• `clearPlan()` prevents re-execution after completion |
| **BundleExecutor.sol** | Every 30s | Automation + CCIP | • `checkUpkeep()` monitors PlanStore for valid plans<br/>• Validates sufficient WETH balance and gas prices<br/>• `performUpkeep()` executes complete arbitrage cycle<br/>• `_executeArbitrage()` swaps WETH→CCIP-BnM and sends CCIP message |
| **RemoteExecutor.sol** | Event-driven | CCIP | • `_ccipReceive()` handles incoming cross-chain messages<br/>• Validates sender authorization and chain selector<br/>• `_completeArbitrage()` swaps CCIP-BnM→WETH<br/>• Transfers profit to treasury and completes cycle |

#### **🔄 Complete 13-Step Execution Flow**
1. Timer triggers Consumer every 5 minutes
2. Consumer calls Chainlink Functions with market data request
3. Functions executes HTTP call to CrossLink AI API
4. API analyzes market conditions using Amazon Bedrock
5. Functions returns AI decision CSV to Consumer
6. Consumer auto-parses CSV and stores plan in PlanStore
7. Automation monitors PlanStore every 30 seconds
8. When plan is valid, Automation triggers BundleExecutor
9. BundleExecutor swaps WETH→CCIP-BnM on source chain
10. BundleExecutor sends CCIP message with tokens to destination
11. CCIP delivers message and tokens to RemoteExecutor
12. RemoteExecutor swaps CCIP-BnM→WETH on destination chain
13. RemoteExecutor transfers profit to treasury, cycle complete

---

## 🧠 **AI Decision Engine Architecture**

### **Market Data Processing Pipeline**

```mermaid
flowchart TD
    START["🚀 Market Analysis Cycle"] --> PARALLEL_FETCH
    
    subgraph "Data Collection"
        PARALLEL_FETCH["Parallel RPC Calls"] --> ETH_RESERVES["ETH Pool Reserves - getReserves() call"]
        PARALLEL_FETCH --> ARB_RESERVES["ARB Pool Reserves - getReserves() call"]
        PARALLEL_FETCH --> ETH_GAS["ETH Gas Price - eth_gasPrice"]
        PARALLEL_FETCH --> ARB_GAS["ARB Gas Price - eth_gasPrice"]
    end
    
    ETH_RESERVES --> PRICE_CALC
    ARB_RESERVES --> PRICE_CALC
    
    subgraph "Price Analysis"
        PRICE_CALC["Price Calculation"] --> ETH_PRICE["ETH Price: WETH/CCIP-BnM"]
        PRICE_CALC --> ARB_PRICE["ARB Price: WETH/CCIP-BnM"]
        ETH_PRICE --> SPREAD["Price Spread Analysis"]
        ARB_PRICE --> SPREAD
        SPREAD --> EDGE["Edge Calculation - Basis Points"]
    end
    
    EDGE --> AI_ENGINE
    ETH_GAS --> AI_ENGINE
    ARB_GAS --> AI_ENGINE
    
    subgraph "AI Decision Making"
        AI_ENGINE{"Amazon Bedrock Available?"}
        AI_ENGINE -->|Yes| BEDROCK["🤖 Bedrock Analysis - Prompt Engineering"]
        AI_ENGINE -->|No| RULES["📏 Rule-Based Logic - Fallback System"]
        
        BEDROCK --> AI_DECISION["AI Decision Output"]
        RULES --> RULE_DECISION["Rule Decision Output"]
        
        AI_DECISION --> FORMAT
        RULE_DECISION --> FORMAT
    end
    
    FORMAT["CSV Formatting - execute,amount,minEdge,maxGas"] --> RETURN["Return to Blockchain"]
```

---
