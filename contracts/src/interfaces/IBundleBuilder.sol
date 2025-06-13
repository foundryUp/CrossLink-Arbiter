// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IBundleBuilder
 * @author Arbitrage Bot Team
 * @notice Interface for the main execution contract that handles atomic cross-chain arbitrage
 * @dev This contract orchestrates the entire arbitrage process:
 *      1. Reads arbitrage plans from PlanStore
 *      2. Executes first swap on Arbitrum
 *      3. Initiates CCIP cross-chain transfer
 *      4. Ensures atomic execution through SUAVE bundling
 */
interface IBundleBuilder {
    // ============ STRUCTS ============

    /**
     * @dev Represents a complete arbitrage plan
     */
    struct ArbPlan {
        uint256 id;                    // Unique plan identifier
        uint256 originChainId;         // Origin chain (Arbitrum)
        uint256 destinationChainId;    // Destination chain (Avalanche)
        address tokenIn;               // Input token address
        address tokenOut;              // Output token address
        uint256 amountIn;              // Amount to trade
        uint256 minAmountOut;          // Minimum expected output
        uint256 minProfitBps;          // Minimum profit in basis points
        uint256 maxGasPrice;           // Maximum gas price for execution
        uint256 deadline;              // Plan expiration timestamp
        uint64 ccipChainSelector;      // CCIP chain selector for destination
        bytes routeData;               // Encoded route data for DEX
        bytes32 planHash;              // Hash of plan data for verification
        bool executed;                 // Execution status
    }

    /**
     * @dev Execution result data
     */
    struct ExecutionResult {
        uint256 planId;                // Plan ID that was executed
        uint256 amountIn;              // Actual input amount
        uint256 amountOut;             // Actual output amount
        uint256 profit;                // Realized profit
        uint256 gasUsed;               // Gas consumed
        bytes32 txHash;                // Transaction hash
        bool success;                  // Execution success status
    }

    // ============ EVENTS ============

    /**
     * @dev Emitted when arbitrage execution starts
     */
    event ArbitrageStarted(
        uint256 indexed planId,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn
    );

    /**
     * @dev Emitted when arbitrage execution completes
     */
    event ArbitrageCompleted(
        uint256 indexed planId,
        uint256 profit,
        uint256 gasUsed,
        bool success
    );

    /**
     * @dev Emitted when CCIP message is sent
     */
    event CCIPMessageSent(
        uint256 indexed planId,
        bytes32 indexed messageId,
        uint64 destinationChainSelector,
        uint256 amount
    );

    /**
     * @dev Emitted when emergency stop is triggered
     */
    event EmergencyStop(uint256 indexed planId, string reason);

    // ============ ERRORS ============

    error PlanNotFound(uint256 planId);
    error PlanExpired(uint256 planId, uint256 deadline);
    error PlanAlreadyExecuted(uint256 planId);
    error InsufficientProfit(uint256 expected, uint256 actual);
    error GasPriceTooHigh(uint256 current, uint256 maximum);
    error InvalidTokenPair(address tokenIn, address tokenOut);
    error InsufficientBalance(address token, uint256 required, uint256 available);
    error SlippageTooHigh(uint256 expected, uint256 actual);
    error CCIPTransferFailed(bytes32 messageId);
    error Unauthorized(address caller);

    // ============ MAIN FUNCTIONS ============

    /**
     * @notice Executes an arbitrage plan atomically
     * @param planId The ID of the plan to execute
     * @return result The execution result containing profit and gas data
     */
    function executeArbitrage(uint256 planId) external returns (ExecutionResult memory result);

    /**
     * @notice Checks if a plan is ready for execution
     * @param planId The ID of the plan to check
     * @return upkeepNeeded True if the plan should be executed
     * @return performData Encoded data for execution
     */
    function checkUpkeep(uint256 planId) external view returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice Performs the upkeep for Chainlink Automation
     * @param performData Encoded data containing plan ID and execution parameters
     */
    function performUpkeep(bytes calldata performData) external;

    /**
     * @notice Emergency stop function to halt execution
     * @param planId The plan ID to stop
     * @param reason The reason for stopping
     */
    function emergencyStop(uint256 planId, string calldata reason) external;

    // ============ VIEW FUNCTIONS ============

    /**
     * @notice Gets the current execution status of a plan
     * @param planId The plan ID to query
     * @return status The current execution status
     */
    function getExecutionStatus(uint256 planId) external view returns (ExecutionResult memory status);

    /**
     * @notice Calculates expected profit for a plan
     * @param planId The plan ID to calculate profit for
     * @return expectedProfit The expected profit in basis points
     */
    function calculateExpectedProfit(uint256 planId) external view returns (uint256 expectedProfit);

    /**
     * @notice Gets the current gas price from oracle
     * @return gasPrice Current gas price in gwei
     */
    function getCurrentGasPrice() external view returns (uint256 gasPrice);

    /**
     * @notice Checks if execution conditions are met
     * @param planId The plan ID to check
     * @return canExecute True if all conditions are met
     * @return reason Reason why execution is blocked (if any)
     */
    function canExecute(uint256 planId) external view returns (bool canExecute, string memory reason);

    // ============ ADMIN FUNCTIONS ============

    /**
     * @notice Updates the PlanStore contract address
     * @param newPlanStore The new PlanStore contract address
     */
    function updatePlanStore(address newPlanStore) external;

    /**
     * @notice Updates the EdgeOracle contract address
     * @param newEdgeOracle The new EdgeOracle contract address
     */
    function updateEdgeOracle(address newEdgeOracle) external;

    /**
     * @notice Updates the CCIP router address
     * @param newCCIPRouter The new CCIP router address
     */
    function updateCCIPRouter(address newCCIPRouter) external;

    /**
     * @notice Updates risk parameters
     * @param maxSlippageBps Maximum allowed slippage in basis points
     * @param maxGasMultiplier Maximum gas price multiplier
     */
    function updateRiskParameters(uint256 maxSlippageBps, uint256 maxGasMultiplier) external;

    /**
     * @notice Withdraws stuck tokens (emergency function)
     * @param token The token to withdraw
     * @param amount The amount to withdraw
     * @param to The recipient address
     */
    function emergencyWithdraw(address token, uint256 amount, address to) external;
} 