// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {OwnerIsCreator} from "@chainlink/contracts/src/v0.8/shared/access/OwnerIsCreator.sol";

/**
 * @title PlanStore
 * @notice Stores arbitrage execution plans received from Chainlink Functions
 * @dev This contract receives ABI-encoded plans from Functions and makes them available to BundleExecutor
 */
contract PlanStore is OwnerIsCreator {
    /// @notice Struct to store arbitrage execution plan
    struct ArbitragePlan {
        bool execute;           // Whether to execute the arbitrage
        uint256 amount;         // Amount of WETH to swap (in wei)
        uint256 minEdgeBps;     // Minimum edge in basis points (1 bp = 0.01%)
        uint256 maxGasGwei;     // Maximum gas price in Gwei
        uint256 timestamp;      // When this plan was created
    }

    /// @notice Current active arbitrage plan
    ArbitragePlan public currentPlan;
    
    /// @notice Address of the authorized Functions consumer contract
    address public functionsConsumer;
    
    /// @notice Address of the authorized BundleExecutor contract
    address public bundleExecutor;
    
    /// @notice Event emitted when a new plan is stored
    event PlanUpdated(
        bool execute,
        uint256 amount,
        uint256 minEdgeBps,
        uint256 maxGasGwei,
        uint256 timestamp
    );

    /// @notice Error when caller is not authorized
    error UnauthorizedFulfillment();

    /**
     * @notice Constructor
     * @param _functionsConsumer Address of the authorized Functions consumer
     */
    constructor(address _functionsConsumer) {
        functionsConsumer = _functionsConsumer;
    }

    /**
     * @notice Updates the Functions consumer address
     * @param _functionsConsumer New Functions consumer address
     */
    function setFunctionsConsumer(address _functionsConsumer) external onlyOwner {
        functionsConsumer = _functionsConsumer;
    }

    /**
     * @notice Updates the BundleExecutor address
     * @param _bundleExecutor New BundleExecutor address
     */
    function setBundleExecutor(address _bundleExecutor) external onlyOwner {
        bundleExecutor = _bundleExecutor;
    }

    /**
     * @notice Fulfills the arbitrage plan from Chainlink Functions
     * @param encodedPlan ABI-encoded ArbitragePlan struct
     * @dev This function can only be called by the authorized Functions consumer
     */
    function fulfillPlan(bytes calldata encodedPlan) external {
        if (msg.sender != functionsConsumer) revert UnauthorizedFulfillment();
        
        ArbitragePlan memory plan = abi.decode(encodedPlan, (ArbitragePlan));
        plan.timestamp = block.timestamp;
        
        currentPlan = plan;
        
        emit PlanUpdated(
            plan.execute,
            plan.amount,
            plan.minEdgeBps,
            plan.maxGasGwei,
            plan.timestamp
        );
    }

    /**
     * @notice Gets the current arbitrage plan
     * @return The current ArbitragePlan struct
     */
    function getCurrentPlan() external view returns (ArbitragePlan memory) {
        return currentPlan;
    }

    /**
     * @notice Checks if the current plan should be executed
     * @return True if execute flag is set and plan is recent (< 5 minutes old)
     */
    function shouldExecute() external view returns (bool) {
        return currentPlan.execute && 
               block.timestamp <= currentPlan.timestamp + 300; // 5 minutes max age
    }

    /**
     * @notice Clears the current plan (sets execute to false)
     * @dev Called by BundleExecutor after successful execution
     */
    function clearPlan() external {
        require(
            msg.sender == owner() || 
            msg.sender == functionsConsumer || 
            msg.sender == bundleExecutor, 
            "Unauthorized"
        );
        currentPlan.execute = false;
    }
} 
 