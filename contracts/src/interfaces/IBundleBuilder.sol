// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IBundleBuilder - Simplified Hackathon Interface
 * @notice Interface for cross-chain arbitrage execution
 * @dev Simplified version for 2-week hackathon
 */
interface IBundleBuilder {
    
    // Simplified arbitrage plan structure
    struct ArbPlan {
        address tokenIn;          // Input token address
        address tokenOut;         // Output token address  
        uint256 amountIn;         // Amount to trade
        uint256 exchangeRate;     // Simple exchange rate (18 decimals)
        uint256 expectedProfit;   // Expected profit in wei
        uint256 deadline;         // Execution deadline
        uint64 targetChain;       // Target chain selector
        address targetContract;   // Target contract address
        bool executed;            // Execution status
    }
    
    // Events (simplified)
    event PlanStored(
        uint256 indexed planId,
        address indexed tokenIn,
        uint256 amountIn,
        uint256 expectedProfit
    );
    
    event PlanExecuted(
        uint256 indexed planId,
        uint256 amountOut,
        bool success
    );
    
    event CCIPMessageSent(
        uint64 indexed targetChain,
        address indexed targetContract,
        uint256 amount
    );
    
    event ArbitrageCompleted(
        uint256 finalAmount,
        bool success
    );
    
    // Core functions (simplified)
    function storePlan(ArbPlan memory plan) external;
    function executePlan(uint256 planId) external;
    function getPlan(uint256 planId) external view returns (ArbPlan memory);
    function getNextPlanId() external view returns (uint256);
} 