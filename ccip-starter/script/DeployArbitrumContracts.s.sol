// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {RemoteExecutor} from "../src/RemoteExecutor.sol";
import {MockWETH, MockUSDC} from "../src/mocks/MockTokens.sol";
import {MockUniswapV2Factory, MockUniswapV2Router02} from "../src/mocks/MockUniswapV2.sol";

contract DeployArbitrumContracts is Script {
    // Arbitrum Sepolia CCIP addresses
    address constant ARBITRUM_ROUTER = 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165;
    address constant ARBITRUM_CCIP_BNM = 0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D;
    uint64 constant ETHEREUM_CHAIN_SELECTOR = 16015286601757825753;
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address treasury = vm.envAddress("TREASURY_ADDRESS");
        address bundleExecutor = vm.envAddress("BUNDLE_EXECUTOR_ADDRESS"); // From Ethereum deployment
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Deploying contracts on Arbitrum Sepolia...");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        
        // Deploy mock tokens
        MockWETH weth = new MockWETH();
        console.log("WETH deployed at:", address(weth));
        
        // Deploy Uniswap V2 mock
        MockUniswapV2Factory factory = new MockUniswapV2Factory();
        MockUniswapV2Router02 router = new MockUniswapV2Router02(address(factory), address(weth));
        console.log("Uniswap Factory deployed at:", address(factory));
        console.log("Uniswap Router deployed at:", address(router));
        
        // Create WETH/CCIP-BnM pair
        address pair = factory.createPair(address(weth), ARBITRUM_CCIP_BNM);
        console.log("WETH/CCIP-BnM pair created at:", pair);
        
        // Deploy RemoteExecutor
        RemoteExecutor remoteExecutor = new RemoteExecutor(
            ARBITRUM_ROUTER,
            address(weth),
            ARBITRUM_CCIP_BNM, // Use CCIP-BnM as the token that will be received
            address(router),
            treasury,
            bundleExecutor,
            ETHEREUM_CHAIN_SELECTOR
        );
        console.log("RemoteExecutor deployed at:", address(remoteExecutor));
        
        vm.stopBroadcast();
        
        console.log("\n=== Deployment Summary ===");
        console.log("WETH:", address(weth));
        console.log("Uniswap Factory:", address(factory));
        console.log("Uniswap Router:", address(router));
        console.log("WETH/CCIP-BnM Pair:", pair);
        console.log("RemoteExecutor:", address(remoteExecutor));
        console.log("CCIP-BnM Token:", ARBITRUM_CCIP_BNM);
        console.log("Treasury:", treasury);
        console.log("Authorized BundleExecutor:", bundleExecutor);
    }
} 
