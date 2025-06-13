// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IBundleBuilder} from "./interfaces/IBundleBuilder.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";

/**
 * @title BundleBuilder - Simplified Hackathon Version
 * @notice Executes cross-chain arbitrage opportunities with MEV protection
 * @dev Simplified version for 2-week hackathon - removes complex features
 */
contract BundleBuilder is IBundleBuilder, CCIPReceiver, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Simplified state variables (removed complex mappings)
    mapping(uint256 => ArbPlan) public plans;
    mapping(address => bool) public authorizedSenders;
    uint256 public nextPlanId;
    address public owner;
    IRouterClient public ccipRouter;
    
    // Basic configuration (removed complex risk parameters)
    uint256 public constant MAX_SLIPPAGE = 300; // 3%
    uint256 public constant MIN_PROFIT_BPS = 50; // 0.5%
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier onlyAuthorized() {
        require(authorizedSenders[msg.sender], "Not authorized");
        _;
    }

    constructor(address _ccipRouter) CCIPReceiver(_ccipRouter) {
        owner = msg.sender;
        ccipRouter = IRouterClient(_ccipRouter);
        authorizedSenders[msg.sender] = true;
    }

    /**
     * @notice Store arbitrage plan from Chainlink Functions
     * @param plan The arbitrage plan to store
     */
    function storePlan(ArbPlan memory plan) external onlyAuthorized {
        require(plan.tokenIn != address(0), "Invalid token");
        require(plan.amountIn > 0, "Invalid amount");
        require(plan.expectedProfit > 0, "No profit expected");
        
        plans[nextPlanId] = plan;
        
        emit PlanStored(nextPlanId, plan.tokenIn, plan.amountIn, plan.expectedProfit);
        nextPlanId++;
    }

    /**
     * @notice Execute arbitrage plan (simplified)
     * @param planId The plan ID to execute
     */
    function executePlan(uint256 planId) external nonReentrant {
        ArbPlan memory plan = plans[planId];
        require(plan.amountIn > 0, "Plan not found");
        require(!plan.executed, "Already executed");
        
        // Mark as executed first (prevent reentrancy)
        plans[planId].executed = true;
        
        // Simple validation (removed complex risk checks)
        require(_validatePlan(plan), "Plan validation failed");
        
        // Execute local swap
        uint256 amountOut = _executeLocalSwap(plan);
        
        // Send tokens cross-chain via CCIP
        _sendCCIPMessage(plan, amountOut);
        
        emit PlanExecuted(planId, amountOut, true);
    }

    /**
     * @notice Simple plan validation (removed complex risk management)
     */
    function _validatePlan(ArbPlan memory plan) internal view returns (bool) {
        // Basic checks only
        return plan.amountIn > 0 && 
               plan.expectedProfit > 0 &&
               block.timestamp <= plan.deadline;
    }

    /**
     * @notice Execute local swap (simplified)
     * @dev In real implementation, would integrate with DEX protocols
     */
    function _executeLocalSwap(ArbPlan memory plan) internal returns (uint256) {
        // SIMPLIFIED: In hackathon, this would integrate with actual DEX
        // For demo purposes, we'll simulate the swap
        
        IERC20 tokenIn = IERC20(plan.tokenIn);
        require(tokenIn.balanceOf(address(this)) >= plan.amountIn, "Insufficient balance");
        
        // Simulate swap logic (replace with real DEX integration)
        uint256 amountOut = plan.amountIn * plan.exchangeRate / 1e18;
        
        // Simple slippage check
        uint256 minAmountOut = amountOut * (10000 - MAX_SLIPPAGE) / 10000;
        require(amountOut >= minAmountOut, "Slippage too high");
        
        return amountOut;
    }

    /**
     * @notice Send CCIP message to destination chain (simplified)
     */
    function _sendCCIPMessage(ArbPlan memory plan, uint256 amount) internal {
        // Simplified CCIP message
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(plan.targetContract),
            data: abi.encodeWithSignature("completeArbitrage(uint256,address)", amount, plan.tokenOut),
            tokenAmounts: new Client.EVMTokenAmount[](1),
            feeToken: address(0), // Native token for fees
            extraArgs: ""
        });
        
        message.tokenAmounts[0] = Client.EVMTokenAmount({
            token: plan.tokenIn,
            amount: amount
        });
        
        // Calculate and pay CCIP fee
        uint256 fee = ccipRouter.getFee(plan.targetChain, message);
        require(address(this).balance >= fee, "Insufficient fee");
        
        ccipRouter.ccipSend{value: fee}(plan.targetChain, message);
        
        emit CCIPMessageSent(plan.targetChain, plan.targetContract, amount);
    }

    /**
     * @notice Handle incoming CCIP messages (simplified)
     */
    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        // Simplified message handling
        address sender = abi.decode(message.sender, (address));
        require(authorizedSenders[sender], "Unauthorized sender");
        
        // Process the arbitrage completion
        (uint256 finalAmount, bool success) = abi.decode(message.data, (uint256, bool));
        
        emit ArbitrageCompleted(finalAmount, success);
    }

    /**
     * @notice Emergency functions (simplified)
     */
    function withdrawToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner, amount);
    }
    
    function withdrawETH() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    
    function addAuthorizedSender(address sender) external onlyOwner {
        authorizedSenders[sender] = true;
    }
    
    function removeAuthorizedSender(address sender) external onlyOwner {
        authorizedSenders[sender] = false;
    }

    // Receive ETH for CCIP fees
    receive() external payable {}
    
    // View functions
    function getPlan(uint256 planId) external view returns (ArbPlan memory) {
        return plans[planId];
    }
    
    function getNextPlanId() external view returns (uint256) {
        return nextPlanId;
    }
} 