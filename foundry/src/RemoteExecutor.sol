// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {CCIPReceiver} from "@chainlink/contracts-ccip/contracts/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";
import {IERC20} from "@chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {Withdraw} from "./utils/Withdraw.sol";

/**
 * @title RemoteExecutor
 * @notice Completes arbitrage execution on Arbitrum and completes the arbitrage
 * @dev Receives USDC via CCIP and swaps it to WETH, then sends profit to treasury
 */
contract RemoteExecutor is CCIPReceiver, Withdraw {
    using SafeERC20 for IERC20;

    /// @notice WETH token address on Arbitrum
    address public immutable weth;
    
    /// @notice USDC token address on Arbitrum
    address public immutable usdc;
    
    /// @notice Uniswap V2 Router address on Arbitrum
    address public immutable uniswapRouter;
    
    /// @notice Treasury address that receives the arbitrage profits
    address public immutable profitTreasury;
    
    /// @notice Authorized BundleExecutor address on source chain - Now mutable to fix circular dependency
    address public authorizedSender;
    
    /// @notice Flag to ensure authorized sender can only be set once
    bool public authorizedSenderSet;
    
    /// @notice Source chain selector (Ethereum Sepolia)
    uint64 public immutable sourceChainSelector;
    
    /// @notice Minimum profit threshold in WETH (to cover gas costs)
    uint256 public minProfitThreshold = 0.001 ether;

    /// @notice Events
    event ArbitrageCompleted(
        bytes32 indexed messageId,
        uint256 usdcReceived,
        uint256 wethObtained,
        uint256 profitSent
    );
    event MinProfitThresholdUpdated(uint256 newThreshold);
    event EmergencyWithdrawal(address token, uint256 amount);
    event AuthorizedSenderSet(address indexed authorizedSender);

    /// @notice Errors
    error UnauthorizedSender();
    error UnauthorizedChain();
    error SwapFailed();
    error InsufficientProfit();
    error TransferFailed();
    error AuthorizedSenderAlreadySet();
    error AuthorizedSenderNotSet();
    error ZeroAddress();

    /**
     * @notice Constructor
     * @param _router CCIP router address
     * @param _weth WETH token address on Arbitrum
     * @param _usdc USDC token address on Arbitrum
     * @param _uniswapRouter Uniswap V2 Router address on Arbitrum
     * @param _profitTreasury Treasury address for profits
     * @param _sourceChainSelector Source chain selector (Ethereum Sepolia)
     */
    constructor(
        address _router,
        address _weth,
        address _usdc,
        address _uniswapRouter,
        address _profitTreasury,
        uint64 _sourceChainSelector
    ) CCIPReceiver(_router) {
        weth = _weth;
        usdc = _usdc;
        uniswapRouter = _uniswapRouter;
        profitTreasury = _profitTreasury;
        sourceChainSelector = _sourceChainSelector;
    }

    /**
     * @notice Sets the authorized sender address - can only be called once by owner
     * @param _authorizedSender Address of the BundleExecutor contract on Ethereum
     */
    function setAuthorizedSender(address _authorizedSender) external onlyOwner {
        if (authorizedSenderSet) revert AuthorizedSenderAlreadySet();
        if (_authorizedSender == address(0)) revert ZeroAddress();
        
        authorizedSender = _authorizedSender;
        authorizedSenderSet = true;
        
        emit AuthorizedSenderSet(_authorizedSender);
    }

    /**
     * @notice Updates minimum profit threshold
     * @param _minProfitThreshold New minimum profit threshold in WETH
     */
    function setMinProfitThreshold(uint256 _minProfitThreshold) external onlyOwner {
        minProfitThreshold = _minProfitThreshold;
        emit MinProfitThresholdUpdated(_minProfitThreshold);
    }

    /**
     * @notice Internal CCIP receive function
     * @param message The CCIP message containing USDC and swap instructions
     */
    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        // Check if authorized sender is set
        if (!authorizedSenderSet) revert AuthorizedSenderNotSet();
        
        // Verify the message is from authorized sender and source chain
        if (message.sourceChainSelector != sourceChainSelector) {
            revert UnauthorizedChain();
        }
        
        address sender = abi.decode(message.sender, (address));
        if (sender != authorizedSender) {
            revert UnauthorizedSender();
        }

        // Decode the swap data
        (uint256 usdcAmount, uint256 deadline) = abi.decode(message.data, (uint256, uint256));
        
        // Verify we received the expected token amount
        // Note: We accept either USDC or the token specified in the message
        require(
            message.destTokenAmounts.length == 1 && 
            message.destTokenAmounts[0].amount == usdcAmount,
            "Invalid token transfer"
        );
        
        // Get the actual token received (could be USDC or CCIP-BnM)
        address receivedToken = message.destTokenAmounts[0].token;

        // Execute the arbitrage completion with the actual received token
        _completeArbitrage(message.messageId, receivedToken, usdcAmount, deadline);
    }

    /**
     * @notice Completes the arbitrage by swapping received token to WETH and sending profit
     * @param messageId CCIP message ID for tracking
     * @param receivedToken Address of the token received via CCIP
     * @param tokenAmount Amount of token to swap
     * @param deadline Swap deadline
     */
    function _completeArbitrage(
        bytes32 messageId,
        address receivedToken,
        uint256 tokenAmount,
        uint256 deadline
    ) internal {
        // Swap received token to WETH
        uint256 wethObtained = _swapTokenToWETH(receivedToken, tokenAmount, deadline);
        
        // Calculate profit (assuming we need to cover the initial WETH that was used on source chain)
        // In a real scenario, you'd track the initial WETH amount used
        uint256 profit = wethObtained;
        
        // Ensure minimum profit threshold is met
        if (profit < minProfitThreshold) {
            revert InsufficientProfit();
        }
        
        // Send profit to treasury
        IERC20(weth).safeTransfer(profitTreasury, profit);
        
        emit ArbitrageCompleted(messageId, tokenAmount, wethObtained, profit);
    }

    /**
     * @notice Swaps any token to WETH using Uniswap V2
     * @param tokenIn Address of input token
     * @param tokenAmount Amount of input token to swap
     * @param deadline Swap deadline
     * @return wethAmount Amount of WETH obtained
     */
    function _swapTokenToWETH(
        address tokenIn,
        uint256 tokenAmount,
        uint256 deadline
    ) internal returns (uint256 wethAmount) {
        // Approve Uniswap router to spend input token
        IERC20(tokenIn).safeApprove(uniswapRouter, tokenAmount);
        
        // Prepare swap path: TokenIn -> WETH
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = weth;
        
        // Record WETH balance before swap
        uint256 wethBefore = IERC20(weth).balanceOf(address(this));
        
        // Execute swap
        try IUniswapV2Router(uniswapRouter).swapExactTokensForTokens(
            tokenAmount,
            0, // Accept any amount of WETH
            path,
            address(this),
            deadline
        ) returns (uint256[] memory amounts) {
            wethAmount = amounts[1];
        } catch {
            revert SwapFailed();
        }
        
        // Verify we received WETH
        uint256 wethAfter = IERC20(weth).balanceOf(address(this));
        require(wethAfter > wethBefore, "No WETH received");
        
        wethAmount = wethAfter - wethBefore;
    }

    /**
     * @notice Gets the expected WETH output for a given token input
     * @param tokenIn Input token address
     * @param tokenAmount Amount of input token to swap
     * @return wethAmount Expected amount of WETH
     */
    function getExpectedWETHOutput(address tokenIn, uint256 tokenAmount) external view returns (uint256 wethAmount) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = weth;
        
        try IUniswapV2Router(uniswapRouter).getAmountsOut(tokenAmount, path) returns (uint256[] memory amounts) {
            wethAmount = amounts[1];
        } catch {
            wethAmount = 0;
        }
    }

    /**
     * @notice Emergency withdrawal function
     * @param token Token to withdraw
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
        emit EmergencyWithdrawal(token, amount);
    }

    /**
     * @notice Gets contract balances for monitoring
     * @return wethBalance WETH balance
     * @return usdcBalance USDC balance
     */
    function getBalances() external view returns (uint256 wethBalance, uint256 usdcBalance) {
        wethBalance = IERC20(weth).balanceOf(address(this));
        usdcBalance = IERC20(usdc).balanceOf(address(this));
    }
    
    /**
     * @notice Gets contract balance for a specific token
     * @param token Token address to check balance for
     * @return balance Token balance
     */
    function getTokenBalance(address token) external view returns (uint256 balance) {
        balance = IERC20(token).balanceOf(address(this));
    }
    
    /**
     * @notice Allows contract to receive ETH for gas costs
     */
    receive() external payable {}
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
    
    function getAmountsOut(uint amountIn, address[] calldata path)
        external view returns (uint[] memory amounts);
} 
 