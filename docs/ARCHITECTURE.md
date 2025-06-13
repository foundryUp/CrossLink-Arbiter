# 🏛️ Cross-Domain Arbitrage Bot - Hackathon Architecture

## 📋 Table of Contents

1. [System Overview](#system-overview)
2. [Simplified Architecture](#simplified-architecture)
3. [Data Flow](#data-flow)
4. [Smart Contract Architecture](#smart-contract-architecture)
5. [AI Agent Architecture](#ai-agent-architecture)
6. [Chainlink Integration](#chainlink-integration)
7. [SUAVE Integration](#suave-integration)
8. [Local Development Setup](#local-development-setup)

## System Overview

The Cross-Domain Arbitrage Bot is a **simplified MEV system** designed for hackathon demonstration. It automatically detects and executes profitable arbitrage opportunities between Arbitrum and Avalanche networks using Chainlink CCIP and SUAVE Helios for MEV protection.

### 🎯 Hackathon Objectives

- **Working Demo**: Demonstrate complete cross-chain arbitrage flow
- **AI Integration**: Amazon Bedrock for intelligent decision making
- **Chainlink Services**: Functions, Automation, and CCIP integration
- **MEV Protection**: SUAVE bundle submission for atomic execution
- **Real-time Monitoring**: Live dashboard for tracking operations

### Key Principles (Simplified)

- **Functionality over Complexity**: Working flow over production-ready features
- **Local Development**: No cloud deployment requirements
- **Demo-Ready**: Visual monitoring and clear logging
- **2-Week Timeline**: Rapid development and testing

## Simplified Architecture

```mermaid
graph TB
    subgraph "AI Agents (Python)"
        A1[Watcher Agent<br/>agents/watcher.py]
        A2[Planner Agent<br/>agents/planner.py] 
        A3[Executor Agent<br/>agents/executor.py]
    end
    
    subgraph "Chainlink Services"
        B1[Functions<br/>chainlink/functions/]
        B2[Automation<br/>chainlink/automation/]
        B3[CCIP Bridge]
    end
    
    subgraph "Smart Contracts"
        C1[BundleBuilder<br/>contracts/src/]
        C2[RemoteExecutor<br/>Avalanche]
    end
    
    subgraph "MEV Protection"
        D1[SUAVE Bundle<br/>suave/bundle_builder.py]
    end
    
    subgraph "Monitoring"
        E1[Dashboard<br/>monitoring/dashboard.py]
        E2[SQLite DB<br/>arbitrage_data.db]
    end
    
    A1 --> A2
    A2 --> A3
    A2 --> B1
    B1 --> B2
    B2 --> C1
    C1 --> D1
    C1 --> B3
    A3 --> E2
    E2 --> E1
    D1 --> E1
```

### Component Responsibilities (Hackathon Version)

| Component | Purpose | Technology | Implementation |
|-----------|---------|------------|----------------|
| **Watcher Agent** | Monitor prices and detect opportunities | Python + SQLite | Single file with basic monitoring |
| **Planner Agent** | AI-powered plan generation | Python + Amazon Bedrock | Bedrock API integration |
| **Executor Agent** | Coordinate execution flow | Python + Web3 | Simple orchestration logic |
| **BundleBuilder** | Execute arbitrage trades | Solidity | Simplified contract with pseudo-code |
| **SUAVE Integration** | MEV protection | Python + SUAVE API | Bundle creation and submission |
| **Dashboard** | Real-time monitoring | FastAPI + HTML | Single-file web dashboard |

## Data Flow

### 1. Simplified Opportunity Detection Flow

```mermaid
sequenceDiagram
    participant W as Watcher Agent
    participant P as Planner Agent
    participant B as Amazon Bedrock
    participant DB as SQLite Database
    
    W->>W: Monitor DEX prices
    W->>W: Detect price discrepancy
    W->>P: Send opportunity data
    P->>B: AI validation request
    B->>P: Approved/Rejected + confidence
    P->>DB: Store approved plan
    DB->>DB: Emit plan ready event
```

### 2. Simplified Execution Flow

```mermaid
sequenceDiagram
    participant CF as Chainlink Functions
    participant Auto as Chainlink Automation
    participant BB as BundleBuilder
    participant SUAVE as SUAVE Bundle
    participant CCIP as Chainlink CCIP
    participant Dashboard as Monitoring
    
    CF->>CF: Fetch approved plans from API
    CF->>Auto: Trigger execution
    Auto->>BB: Execute arbitrage
    BB->>SUAVE: Submit MEV bundle
    BB->>CCIP: Cross-chain message
    SUAVE->>SUAVE: Include in block
    BB->>Dashboard: Update execution status
```

## Smart Contract Architecture

### Simplified Contract Structure

```
BundleBuilder (Main Contract)
├── Basic arbitrage execution
├── CCIP integration
├── Simple access control
└── Event emission

RemoteExecutor (Destination Chain)
├── CCIP message receiver
├── DEX swap execution
└── Profit tracking
```

### Simplified Storage Layout

```solidity
// Simplified ArbPlan structure
struct ArbPlan {
    address tokenIn;          // Input token
    address tokenOut;         // Output token  
    uint256 amountIn;         // Trade amount
    uint256 expectedProfit;   // Expected profit
    uint256 deadline;         // Execution deadline
    uint64 targetChain;       // Destination chain
    bool executed;            // Execution status
}
```

## AI Agent Architecture

### Single-File Agent Design

```mermaid
graph LR
    subgraph "agents/watcher.py"
        W1[Price Monitoring]
        W2[Opportunity Detection]
        W3[SQLite Storage]
    end
    
    subgraph "agents/planner.py"
        P1[Size Optimization]
        P2[Amazon Bedrock AI]
        P3[Plan Generation]
    end
    
    subgraph "agents/executor.py"
        E1[Plan Monitoring]
        E2[Execution Coordination]
        E3[Status Tracking]
    end
    
    W1 --> W2
    W2 --> W3
    W3 --> P1
    P1 --> P2
    P2 --> P3
    P3 --> E1
    E1 --> E2
    E2 --> E3
```

### AI Integration Points

1. **Amazon Bedrock Claude**: Plan validation and optimization
2. **Simple Logic**: Basic slippage and gas estimation
3. **Local SQLite**: Data persistence without external dependencies
4. **Async Processing**: Non-blocking operation handling

## Chainlink Integration

### Functions Integration
```javascript
// Simplified Functions source
const source = `
// Fetch approved plans from local API
const response = await Functions.makeHttpRequest({
    url: "http://localhost:8080/api/approved-plans"
});

// Return best plan for execution
return Functions.encodeString(JSON.stringify(bestPlan));
`;
```

### Automation Setup
```javascript
// Register upkeep for plan execution
const upkeepConfig = {
    name: "Cross-Chain Arbitrage Bot",
    upkeepContract: bundleBuilderAddress,
    gasLimit: 500000,
    amount: ethers.utils.parseEther("5") // 5 LINK
};
```

### CCIP Configuration
- **Source Chain**: Arbitrum Sepolia
- **Destination Chain**: Avalanche Fuji  
- **Token Bridging**: WETH, USDC
- **Message Passing**: Execution instructions

## SUAVE Integration

### Bundle Creation Process

```python
# Simplified bundle structure
bundle = {
    "version": "v0.1",
    "inclusion": {"block": "latest", "maxBlock": "latest+2"},
    "body": [{
        "tx": {
            "to": bundleBuilderAddress,
            "data": executeCallData,
            "gasLimit": "0x7A120"
        }
    }]
}
```

### MEV Protection Features
- **Bundle Submission**: Atomic transaction grouping
- **Privacy**: Hide transaction content until inclusion
- **Revert Protection**: All-or-nothing execution
- **Fair Ordering**: Protection against frontrunning

## Local Development Setup

### Database Architecture
```sql
-- SQLite tables for hackathon
CREATE TABLE price_data (
    id INTEGER PRIMARY KEY,
    chain TEXT,
    dex TEXT,
    token_pair TEXT,
    price REAL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE opportunities (
    id INTEGER PRIMARY KEY,
    token TEXT,
    chain_a TEXT,
    chain_b TEXT,
    price_a REAL,
    price_b REAL,
    spread_bps INTEGER,
    profit_estimate REAL,
    status TEXT DEFAULT 'detected',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE arbitrage_plans (
    plan_id TEXT PRIMARY KEY,
    token TEXT,
    trade_size_usd REAL,
    expected_profit REAL,
    status TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE executions (
    id INTEGER PRIMARY KEY,
    plan_id TEXT,
    tx_hash TEXT,
    expected_profit REAL,
    actual_profit REAL,
    status TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### File Structure
```
├── agents/
│   ├── watcher.py      # Price monitoring
│   ├── planner.py      # AI planning with Bedrock
│   └── executor.py     # Execution coordination
├── chainlink/
│   ├── functions/      # Chainlink Functions
│   └── automation/     # Chainlink Automation
├── contracts/
│   └── src/           # Simplified smart contracts
├── suave/
│   └── bundle_builder.py  # MEV protection
├── monitoring/
│   └── dashboard.py    # Web dashboard
└── scripts/
    └── test_full_flow.py  # End-to-end testing
```

### Development Workflow

1. **Local Setup**: SQLite database and Python virtual environment
2. **Agent Testing**: Individual component testing with mock data
3. **Integration Testing**: Full flow testing with `scripts/test_full_flow.py`
4. **Dashboard Monitoring**: Real-time visualization at `localhost:8080`
5. **Contract Deployment**: Testnet deployment for Chainlink integration

### Performance Expectations

- **Opportunity Detection**: ~5-10 seconds
- **AI Plan Generation**: ~2-5 seconds  
- **Bundle Creation**: ~1-2 seconds
- **Cross-chain Execution**: ~30-60 seconds
- **Total Flow Time**: ~1-2 minutes per opportunity

This simplified architecture enables rapid development and demonstration while maintaining the core cross-chain arbitrage functionality with AI decision-making and MEV protection. 