// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IERC20} from "@chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";
import {Withdraw} from "./utils/Withdraw.sol";
import {PlanStore} from "./PlanStore.sol";

/**
 * @title BundleExecutor
 * @notice Executes cross-chain arbitrage opportunities on Ethereum Sepolia
 * @dev This contract is triggered by Chainlink Automation when profitable opportunities exist
 */
contract BundleExecutor is AutomationCompatibleInterface, Withdraw {
    using SafeERC20 for IERC20;

    /// @notice Struct for swap execution parameters
    struct SwapParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        address to;
        uint256 deadline;
    }

    /// @notice PlanStore contract that contains arbitrage plans
    PlanStore public immutable planStore;

    /// @notice CCIP Router for cross-chain messaging
    IRouterClient public immutable ccipRouter;

    /// @notice LINK token for CCIP fees
    LinkTokenInterface public immutable linkToken;

    /// @notice Destination chain selector for Arbitrum Sepolia
    uint64 public immutable destinationChainSelector;

    /// @notice Remote executor address on Arbitrum - Now mutable to fix circular dependency
    address public remoteExecutor;

    /// @notice Flag to ensure remote executor can only be set once
    bool public remoteExecutorSet;

    /// @notice WETH token address
    address public immutable weth;

    /// @notice CCIP-BnM token address (cross-chain token)
    address public immutable ccipBnM;

    /// @notice Uniswap V2 Router address
    address public immutable uniswapRouter;

    /// @notice Ethereum WETH/CCIP-BnM pair address
    address public immutable ethereumPair;

    /// @notice Arbitrum WETH/CCIP-BnM pair address
    address public immutable arbitrumPair;

    /// @notice Maximum gas price for execution (in wei)
    uint256 public maxGasPrice = 50 gwei;

    /// @notice Events
    event ArbitrageExecuted(
        uint256 wethAmount,
        uint256 usdcAmount,
        bytes32 ccipMessageId
    );
    event MaxGasPriceUpdated(uint256 newMaxGasPrice);
    event RemoteExecutorSet(address indexed remoteExecutor);

    /// @notice Errors
    error GasPriceTooHigh();
    error SwapFailed();
    error InsufficientBalance();
    error CCIPSendFailed();
    error RemoteExecutorAlreadySet();
    error RemoteExecutorNotSet();
    error ZeroAddress();

    /**
     * @notice Constructor
     * @param _planStore Address of the PlanStore contract
     * @param _ccipRouter Address of the CCIP router
     * @param _linkToken Address of LINK token
     * @param _destinationChainSelector Chain selector for Arbitrum Sepolia
     * @param _weth WETH token address
     * @param _ccipBnM CCIP-BnM token address
     * @param _uniswapRouter Uniswap V2 Router address
     * @param _ethereumPair Ethereum WETH/CCIP-BnM pair address
     * @param _arbitrumPair Arbitrum WETH/CCIP-BnM pair address
     */
    constructor(
        address _planStore,
        address _ccipRouter,
        address _linkToken,
        uint64 _destinationChainSelector,
        address _weth,
        address _ccipBnM,
        address _uniswapRouter,
        address _ethereumPair,
        address _arbitrumPair
    ) {
        planStore = PlanStore(_planStore);
        ccipRouter = IRouterClient(_ccipRouter);
        linkToken = LinkTokenInterface(_linkToken);
        destinationChainSelector = _destinationChainSelector;
        weth = _weth;
        ccipBnM = _ccipBnM;
        uniswapRouter = _uniswapRouter;
        ethereumPair = _ethereumPair;
        arbitrumPair = _arbitrumPair;
    }

    /**
     * @notice Sets the remote executor address - can only be called once by owner
     * @param _remoteExecutor Address of the RemoteExecutor contract on Arbitrum
     */
    function setRemoteExecutor(address _remoteExecutor) external onlyOwner {
        if (remoteExecutorSet) revert RemoteExecutorAlreadySet();
        if (_remoteExecutor == address(0)) revert ZeroAddress();

        remoteExecutor = _remoteExecutor;
        remoteExecutorSet = true;

        emit RemoteExecutorSet(_remoteExecutor);
    }

    receive() external payable {}

    /**
     * @notice Updates maximum gas price for execution
     * @param _maxGasPrice New maximum gas price in wei
     */
    function setMaxGasPrice(uint256 _maxGasPrice) external onlyOwner {
        maxGasPrice = _maxGasPrice;
        emit MaxGasPriceUpdated(_maxGasPrice);
    }

    /**
     * @notice Chainlink Automation checkUpkeep function
     * @return upkeepNeeded True if arbitrage should be executed
     * @return performData Empty bytes (not used)
     */
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // Check if remote executor is set
        if (!remoteExecutorSet) return (false, "");

        // Check if there's a valid arbitrage plan
        bool shouldExecute = planStore.shouldExecute();

        // Check gas price constraint
        bool gasOk = tx.gasprice <= maxGasPrice;

        // Check if we have sufficient WETH balance
        PlanStore.ArbitragePlan memory plan = planStore.getCurrentPlan();
        bool balanceOk = IERC20(weth).balanceOf(address(this)) >= plan.amount;

        upkeepNeeded = shouldExecute && gasOk && balanceOk;
        performData = "";
    }

    /**
     * @notice Chainlink Automation performUpkeep function
     * @dev Executes the arbitrage when conditions are met
     */
    function performUpkeep(bytes calldata /* performData */) external override {
        if (!remoteExecutorSet) revert RemoteExecutorNotSet();

        PlanStore.ArbitragePlan memory plan = planStore.getCurrentPlan();

        // Verify execution conditions
        if (!planStore.shouldExecute()) revert("No valid plan");
        if (tx.gasprice > maxGasPrice) revert GasPriceTooHigh();
        if (IERC20(weth).balanceOf(address(this)) < plan.amount)
            revert InsufficientBalance();

        // Execute the arbitrage
        _executeArbitrage(plan);

        // Clear the plan to prevent re-execution
        planStore.clearPlan();
    }

    /**
     * @notice Internal function to execute arbitrage
     * @param plan The arbitrage plan to execute
     */
    function _executeArbitrage(PlanStore.ArbitragePlan memory plan) internal {
        // Step 1: Swap WETH to CCIP-BnM on Ethereum Sepolia
        address;
        path[0] = weth;
        path[1] = ccipBnM;

        uint256[] memory amountsOut = IUniswapV2Router(uniswapRouter)
            .getAmountsOut(plan.amount, path);
        uint256 amountOutMin = (amountsOut[1] * 995) / 1000; // 0.5% slippage guard

        uint256 ccipBnMAmount = _swapWETHtoCCIPBnM(plan.amount, amountOutMin);

        // Step 2: Prepare CCIP message with CCIP-BnM and remote swap instructions
        bytes memory remoteSwapData = abi.encode(
            ccipBnMAmount,
            block.timestamp + 3600 // 1 hour deadline
        );

        // Step 3: Send CCIP-BnM + instructions to Arbitrum via CCIP
        bytes32 messageId = _sendCCIPMessage(ccipBnMAmount, remoteSwapData);

        emit ArbitrageExecuted(plan.amount, ccipBnMAmount, messageId);
    }

    /**
     * @notice Swaps WETH to CCIP-BnM using Uniswap V2
     * @param wethAmount Amount of WETH to swap
     * @return ccipBnMAmount Amount of CCIP-BnM received
     */
    function _swapWETHtoCCIPBnM(
        uint256 wethAmount,
        uint256 minOut
    ) internal returns (uint256 ccipBnMAmount) {
        IERC20(weth).safeApprove(uniswapRouter, wethAmount);

        address;
        path[0] = weth;
        path[1] = ccipBnM;

        uint256 ccipBnMBefore = IERC20(ccipBnM).balanceOf(address(this));

        try
            IUniswapV2Router(uniswapRouter).swapExactTokensForTokens(
                wethAmount,
                minOut, 
                path,
                address(this),
                block.timestamp + 120
            )
        returns (uint256[] memory amounts) {
            ccipBnMAmount = amounts[1];
        } catch {
            revert SwapFailed();
        }

        uint256 ccipBnMAfter = IERC20(ccipBnM).balanceOf(address(this));
        require(ccipBnMAfter > ccipBnMBefore, "No CCIP-BnM received");

        ccipBnMAmount = ccipBnMAfter - ccipBnMBefore;
    }

    /**
     * @notice Sends CCIP-BnM and swap instructions to Arbitrum via CCIP
     * @param ccipBnMAmount Amount of CCIP-BnM to send
     * @param swapData Encoded swap instructions for remote executor
     * @return messageId CCIP message ID
     */
    function _sendCCIPMessage(
        uint256 ccipBnMAmount,
        bytes memory swapData
    ) internal returns (bytes32 messageId) {
        // Approve CCIP router to spend CCIP-BnM
        IERC20(ccipBnM).safeApprove(address(ccipRouter), ccipBnMAmount);

        // Prepare token transfer
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: ccipBnM,
            amount: ccipBnMAmount
        });

        // Prepare CCIP message
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(remoteExecutor),
            data: swapData,
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(
                Client.GenericExtraArgsV2({
                    gasLimit: 500_000, // Gas for remote execution
                    allowOutOfOrderExecution: false
                })
            ),
            feeToken: address(linkToken)
        });

        // Calculate and pay CCIP fees
        uint256 fees = ccipRouter.getFee(destinationChainSelector, message);
        linkToken.approve(address(ccipRouter), fees);

        // Send CCIP message
        try ccipRouter.ccipSend(destinationChainSelector, message) returns (
            bytes32 msgId
        ) {
            messageId = msgId;
        } catch {
            revert CCIPSendFailed();
        }
    }

    /**
     * @notice Emergency function to withdraw stuck tokens
     * @param token Token address to withdraw
     * @param to Recipient address
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
}

/**
 * @notice Interface for Uniswap V2 Router
 */
interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}
