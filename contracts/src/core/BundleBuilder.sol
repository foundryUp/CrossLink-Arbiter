// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/CCIPRouter.sol";
import "../interfaces/IBundleBuilder.sol";
import "../interfaces/IPlanStore.sol";
import "../interfaces/IEdgeOracle.sol";

/**
 * @title BundleBuilder
 * @author Arbitrage Bot Team
 * @notice Main execution contract for cross-domain arbitrage
 * @dev Orchestrates atomic arbitrage across Arbitrum and Avalanche
 */
contract BundleBuilder is IBundleBuilder, Ownable, ReentrancyGuard, AutomationCompatible {
    // ============ STATE VARIABLES ============
    
    IPlanStore public planStore;
    IEdgeOracle public edgeOracle;
    address public ccipRouter;
    address public treasury;
    
    // Risk management parameters
    uint256 public maxSlippageBps = 200; // 2%
    uint256 public maxGasMultiplier = 150; // 1.5x
    uint256 public maxTradeSize = 50000e6; // 50k USDC
    uint256 public cooldownPeriod = 300; // 5 minutes
    
    // Execution tracking
    mapping(uint256 => ExecutionResult) public executionResults;
    mapping(uint256 => bool) public planExecuted;
    uint256 public lastExecutionTime;
    uint256 public totalProfitRealized;
    
    // Emergency controls
    bool public emergencyPaused;
    mapping(address => bool) public emergencyOperators;
    
    // ============ EVENTS ============
    
    event ArbitrageExecuted(
        uint256 indexed planId,
        uint256 amountIn,
        uint256 amountOut,
        uint256 profit,
        uint256 gasUsed
    );
    
    // ============ MODIFIERS ============
    
    modifier whenNotPaused() {
        require(!emergencyPaused, "Emergency pause active");
        _;
    }
    
    modifier onlyAutomation() {
        require(msg.sender == automationRegistry, "Only automation");
        _;
    }
    
    modifier validPlan(uint256 planId) {
        require(planStore.planExists(planId), "Plan does not exist");
        require(!planExecuted[planId], "Plan already executed");
        _;
    }
    
    // ============ CONSTRUCTOR ============
    
    constructor(
        address _planStore,
        address _edgeOracle,
        address _ccipRouter,
        address _treasury
    ) {
        planStore = IPlanStore(_planStore);
        edgeOracle = IEdgeOracle(_edgeOracle);
        ccipRouter = _ccipRouter;
        treasury = _treasury;
        emergencyOperators[msg.sender] = true;
    }
    
    // ============ MAIN EXECUTION FUNCTIONS ============
    
    /**
     * @notice Executes an arbitrage plan atomically
     * @param planId The ID of the plan to execute
     * @return result The execution result
     */
    function executeArbitrage(uint256 planId) 
        external 
        nonReentrant 
        whenNotPaused 
        validPlan(planId)
        returns (ExecutionResult memory result) 
    {
        uint256 gasStart = gasleft();
        
        // Load plan from storage
        ArbPlan memory plan = planStore.getPlan(planId);
        
        // Validate execution conditions
        _validateExecutionConditions(plan);
        
        try this._internalExecute(plan) returns (uint256 amountOut) {
            // Calculate realized profit
            uint256 profit = amountOut > plan.amountIn ? 
                amountOut - plan.amountIn : 0;
            
            // Update state
            planExecuted[planId] = true;
            lastExecutionTime = block.timestamp;
            totalProfitRealized += profit;
            
            // Create execution result
            result = ExecutionResult({
                planId: planId,
                amountIn: plan.amountIn,
                amountOut: amountOut,
                profit: profit,
                gasUsed: gasStart - gasleft(),
                txHash: blockhash(block.number - 1),
                success: true
            });
            
            executionResults[planId] = result;
            
            emit ArbitrageExecuted(planId, plan.amountIn, amountOut, profit, result.gasUsed);
            
        } catch Error(string memory reason) {
            // Handle execution failure
            result = ExecutionResult({
                planId: planId,
                amountIn: plan.amountIn,
                amountOut: 0,
                profit: 0,
                gasUsed: gasStart - gasleft(),
                txHash: blockhash(block.number - 1),
                success: false
            });
            
            executionResults[planId] = result;
            
            emit EmergencyStop(planId, reason);
            revert(reason);
        }
    }
    
    /**
     * @notice Internal execution logic (separated for try/catch)
     */
    function _internalExecute(ArbPlan memory plan) external returns (uint256 amountOut) {
        require(msg.sender == address(this), "Internal only");
        
        // Step 1: Execute swap on origin chain (Arbitrum)
        amountOut = _executeOriginSwap(plan);
        
        // Step 2: Send tokens and execution data via CCIP
        bytes32 messageId = _sendCCIPMessage(plan, amountOut);
        
        // Step 3: Submit to SUAVE for atomic execution
        _submitToSUAVE(plan, messageId);
        
        return amountOut;
    }
    
    // ============ CHAINLINK AUTOMATION ============
    
    /**
     * @notice Checks if upkeep is needed for a plan
     */
    function checkUpkeep(bytes calldata checkData) 
        external 
        view 
        override 
        returns (bool upkeepNeeded, bytes memory performData) 
    {
        uint256 planId = abi.decode(checkData, (uint256));
        
        if (!planStore.planExists(planId) || planExecuted[planId]) {
            return (false, "");
        }
        
        ArbPlan memory plan = planStore.getPlan(planId);
        
        // Check all execution conditions
        bool gasOk = tx.gasprice <= plan.maxGasPrice;
        bool deadlineOk = block.timestamp <= plan.deadline;
        bool cooldownOk = block.timestamp >= lastExecutionTime + cooldownPeriod;
        bool profitOk = edgeOracle.deltaEdge(plan.tokenIn, plan.tokenOut) >= plan.minProfitBps;
        bool notPaused = !emergencyPaused;
        
        upkeepNeeded = gasOk && deadlineOk && cooldownOk && profitOk && notPaused;
        performData = upkeepNeeded ? abi.encode(planId, plan) : "";
    }
    
    /**
     * @notice Performs the upkeep
     */
    function performUpkeep(bytes calldata performData) external override onlyAutomation {
        (uint256 planId,) = abi.decode(performData, (uint256, ArbPlan));
        executeArbitrage(planId);
    }
    
    // ============ INTERNAL FUNCTIONS ============
    
    function _validateExecutionConditions(ArbPlan memory plan) internal view {
        // Gas price check
        if (tx.gasprice > plan.maxGasPrice) {
            revert GasPriceTooHigh(tx.gasprice, plan.maxGasPrice);
        }
        
        // Deadline check
        if (block.timestamp > plan.deadline) {
            revert PlanExpired(plan.id, plan.deadline);
        }
        
        // Profit threshold check
        uint256 currentEdge = edgeOracle.deltaEdge(plan.tokenIn, plan.tokenOut);
        if (currentEdge < plan.minProfitBps) {
            revert InsufficientProfit(plan.minProfitBps, currentEdge);
        }
        
        // Cooldown check
        if (block.timestamp < lastExecutionTime + cooldownPeriod) {
            revert("Cooldown period active");
        }
        
        // Trade size check
        if (plan.amountIn > maxTradeSize) {
            revert("Trade size exceeds limit");
        }
    }
    
    function _executeOriginSwap(ArbPlan memory plan) internal returns (uint256 amountOut) {
        // Decode route data to get DEX router and path
        (address router, bytes memory swapData) = abi.decode(plan.routeData, (address, bytes));
        
        // Transfer tokens from treasury
        IERC20(plan.tokenIn).transferFrom(treasury, address(this), plan.amountIn);
        
        // Approve router
        IERC20(plan.tokenIn).approve(router, plan.amountIn);
        
        // Execute swap based on DEX type
        if (router == SUSHISWAP_ROUTER) {
            amountOut = _executeSushiSwap(plan, swapData);
        } else if (router == UNISWAP_V3_ROUTER) {
            amountOut = _executeUniswapV3Swap(plan, swapData);
        } else {
            revert("Unsupported DEX");
        }
        
        // Validate slippage
        uint256 minAmountOut = plan.minAmountOut * (10000 - maxSlippageBps) / 10000;
        if (amountOut < minAmountOut) {
            revert SlippageTooHigh(minAmountOut, amountOut);
        }
    }
    
    function _sendCCIPMessage(ArbPlan memory plan, uint256 amount) internal returns (bytes32 messageId) {
        // Prepare CCIP message
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(plan.destinationExecutor),
            data: abi.encode(plan.id, plan.tokenOut, amount, plan.routeData),
            tokenAmounts: new Client.EVMTokenAmount[](1),
            extraArgs: "",
            feeToken: address(0) // Use native token for fees
        });
        
        message.tokenAmounts[0] = Client.EVMTokenAmount({
            token: plan.tokenOut,
            amount: amount
        });
        
        // Calculate and pay CCIP fees
        uint256 fees = IRouterClient(ccipRouter).getFee(plan.ccipChainSelector, message);
        
        // Send message
        messageId = IRouterClient(ccipRouter).ccipSend{value: fees}(
            plan.ccipChainSelector,
            message
        );
    }
    
    function _submitToSUAVE(ArbPlan memory plan, bytes32 messageId) internal {
        // SUAVE bundle submission logic
        // This would interact with SUAVE network to ensure atomic execution
        // Implementation depends on SUAVE API specifications
        
        // For now, emit event for off-chain SUAVE integration
        emit CCIPMessageSent(plan.id, messageId, plan.ccipChainSelector, plan.amountIn);
    }
    
    // ============ EMERGENCY FUNCTIONS ============
    
    function emergencyPause(string calldata reason) external {
        require(emergencyOperators[msg.sender], "Not authorized");
        emergencyPaused = true;
        emit EmergencyStop(0, reason);
    }
    
    function emergencyResume() external onlyOwner {
        emergencyPaused = false;
        emit EmergencyResume(block.timestamp);
    }
    
    function emergencyWithdraw(address token, uint256 amount, address to) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }
    
    // ============ VIEW FUNCTIONS ============
    
    function getExecutionStatus(uint256 planId) external view returns (ExecutionResult memory) {
        return executionResults[planId];
    }
    
    function calculateExpectedProfit(uint256 planId) external view returns (uint256) {
        ArbPlan memory plan = planStore.getPlan(planId);
        uint256 currentEdge = edgeOracle.deltaEdge(plan.tokenIn, plan.tokenOut);
        return (plan.amountIn * currentEdge) / 10000;
    }
    
    function getCurrentGasPrice() external view returns (uint256) {
        return tx.gasprice;
    }
    
    function canExecute(uint256 planId) external view returns (bool canExecute, string memory reason) {
        if (!planStore.planExists(planId)) {
            return (false, "Plan does not exist");
        }
        
        if (planExecuted[planId]) {
            return (false, "Plan already executed");
        }
        
        if (emergencyPaused) {
            return (false, "Emergency pause active");
        }
        
        ArbPlan memory plan = planStore.getPlan(planId);
        
        if (block.timestamp > plan.deadline) {
            return (false, "Plan expired");
        }
        
        if (tx.gasprice > plan.maxGasPrice) {
            return (false, "Gas price too high");
        }
        
        uint256 currentEdge = edgeOracle.deltaEdge(plan.tokenIn, plan.tokenOut);
        if (currentEdge < plan.minProfitBps) {
            return (false, "Insufficient profit margin");
        }
        
        return (true, "");
    }
    
    // ============ ADMIN FUNCTIONS ============
    
    function updatePlanStore(address newPlanStore) external onlyOwner {
        planStore = IPlanStore(newPlanStore);
    }
    
    function updateEdgeOracle(address newEdgeOracle) external onlyOwner {
        edgeOracle = IEdgeOracle(newEdgeOracle);
    }
    
    function updateCCIPRouter(address newCCIPRouter) external onlyOwner {
        ccipRouter = newCCIPRouter;
    }
    
    function updateRiskParameters(
        uint256 _maxSlippageBps,
        uint256 _maxGasMultiplier
    ) external onlyOwner {
        maxSlippageBps = _maxSlippageBps;
        maxGasMultiplier = _maxGasMultiplier;
    }
} 