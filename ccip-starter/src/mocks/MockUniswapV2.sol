// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title MockUniswapV2Pair
 * @notice Mock Uniswap V2 pair for testing
 */
contract MockUniswapV2Pair {
    using SafeERC20 for IERC20;

    address public token0;
    address public token1;
    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );

    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }

    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function setReserves(uint112 _reserve0, uint112 _reserve1) external {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
        blockTimestampLast = uint32(block.timestamp);
    }

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata) external {
        require(amount0Out > 0 || amount1Out > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        require(amount0Out < reserve0 && amount1Out < reserve1, "INSUFFICIENT_LIQUIDITY");

        if (amount0Out > 0) IERC20(token0).safeTransfer(to, amount0Out);
        if (amount1Out > 0) IERC20(token1).safeTransfer(to, amount1Out);

        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));

        uint amount0In = balance0 > reserve0 - amount0Out ? balance0 - (reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > reserve1 - amount1Out ? balance1 - (reserve1 - amount1Out) : 0;

        require(amount0In > 0 || amount1In > 0, "INSUFFICIENT_INPUT_AMOUNT");

        // Simplified: skip K validation for testing
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);

        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }
}

/**
 * @title MockUniswapV2Factory
 * @notice Mock Uniswap V2 factory for testing
 */
contract MockUniswapV2Factory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "PAIR_EXISTS");

        pair = address(new MockUniswapV2Pair(token0, token1));
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }
}

/**
 * @title MockUniswapV2Router02
 * @notice Mock Uniswap V2 router for testing
 */
contract MockUniswapV2Router02 {
    using SafeERC20 for IERC20;

    address public immutable factory;
    address public immutable WETH;

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        returns (uint[] memory amounts)
    {
        require(path.length >= 2, "INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[0] = amountIn;

        for (uint i; i < path.length - 1; i++) {
            address pair = MockUniswapV2Factory(factory).getPair(path[i], path[i + 1]);
            if (pair != address(0)) {
                (uint112 reserve0, uint112 reserve1,) = MockUniswapV2Pair(pair).getReserves();
                
                // Determine which reserve is for which token
                (uint112 reserveIn, uint112 reserveOut) = path[i] == MockUniswapV2Pair(pair).token0() 
                    ? (reserve0, reserve1) 
                    : (reserve1, reserve0);
                
                // Simple constant product formula (without fees for simplicity)
                amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
            } else {
                amounts[i + 1] = 0; // No pair exists
            }
        }
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        returns (uint amountOut)
    {
        require(amountIn > 0, "INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");
        
        // Simplified: 0.3% fee
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        require(deadline >= block.timestamp, "EXPIRED");
        
        amounts = getAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");
        
        // Transfer input token from user
        IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amounts[0]);
        
        // Execute swaps
        _swap(amounts, path, to);
    }

    function _swap(uint[] memory amounts, address[] memory path, address _to) internal {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            address pair = MockUniswapV2Factory(factory).getPair(input, output);
            require(pair != address(0), "PAIR_NOT_EXISTS");
            
            uint amountOut = amounts[i + 1];
            
            // Transfer input token to pair
            IERC20(input).safeTransfer(pair, amounts[i]);
            
            // Determine output amounts for swap
            (uint amount0Out, uint amount1Out) = input == MockUniswapV2Pair(pair).token0() 
                ? (uint(0), amountOut) 
                : (amountOut, uint(0));
            
            // Execute swap
            address to = i < path.length - 2 ? MockUniswapV2Factory(factory).getPair(output, path[i + 2]) : _to;
            MockUniswapV2Pair(pair).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity) {
        require(deadline >= block.timestamp, "EXPIRED");
        
        address pair = MockUniswapV2Factory(factory).getPair(tokenA, tokenB);
        if (pair == address(0)) {
            pair = MockUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        
        // For simplicity, just use desired amounts
        amountA = amountADesired;
        amountB = amountBDesired;
        
        require(amountA >= amountAMin, "INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "INSUFFICIENT_B_AMOUNT");
        
        // Transfer tokens to pair
        IERC20(tokenA).safeTransferFrom(msg.sender, pair, amountA);
        IERC20(tokenB).safeTransferFrom(msg.sender, pair, amountB);
        
        // Update reserves
        if (tokenA < tokenB) {
            MockUniswapV2Pair(pair).setReserves(uint112(amountA), uint112(amountB));
        } else {
            MockUniswapV2Pair(pair).setReserves(uint112(amountB), uint112(amountA));
        }
        
        liquidity = 1000 * 10**18; // Mock liquidity tokens
    }
} 
 