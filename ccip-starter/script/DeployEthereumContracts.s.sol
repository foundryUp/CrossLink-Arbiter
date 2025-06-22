// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {PlanStore} from "../src/PlanStore.sol";
import {BundleExecutor} from "../src/BundleExecutor.sol";
import {ArbitrageFunctionsConsumer} from "../src/ArbitrageFunctionsConsumer.sol";
import {MockWETH, MockUSDC} from "../src/mocks/MockTokens.sol";
import {MockUniswapV2Factory, MockUniswapV2Router02} from "../src/mocks/MockUniswapV2.sol";

contract DeployEthereumContracts is Script {
    // Ethereum Sepolia CCIP addresses
    address constant ETHEREUM_ROUTER = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;
    address constant ETHEREUM_LINK = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address constant ETHEREUM_CCIP_BNM = 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05;
    uint64 constant ARBITRUM_CHAIN_SELECTOR = 3478487238524512106;
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address functionsConsumer = vm.envAddress("FUNCTIONS_CONSUMER_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Deploying contracts on Ethereum Sepolia...");
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
        address pair = factory.createPair(address(weth), ETHEREUM_CCIP_BNM);
        console.log("WETH/CCIP-BnM pair created at:", pair);
        
        // Use existing PlanStore from Functions Consumer instead of deploying new one
        PlanStore existingPlanStore = ArbitrageFunctionsConsumer(functionsConsumer).planStore();
        console.log("Using existing PlanStore at:", address(existingPlanStore));
        
        // Deploy BundleExecutor WITHOUT RemoteExecutor address (will be set later via setter)
        BundleExecutor bundleExecutor = new BundleExecutor(
            address(existingPlanStore),
            ETHEREUM_ROUTER,
            ETHEREUM_LINK,
            ARBITRUM_CHAIN_SELECTOR,
            address(weth),
            ETHEREUM_CCIP_BNM,
            address(router),
            pair,
            address(0) // Placeholder for arbitrumPair - will be updated manually if needed
        );
        console.log("BundleExecutor deployed at:", address(bundleExecutor));
        
        // Set BundleExecutor as authorized in existing PlanStore
        existingPlanStore.setBundleExecutor(address(bundleExecutor));
        console.log("BundleExecutor authorized in PlanStore");
        
        vm.stopBroadcast();
        
        console.log("\n=== Deployment Summary ===");
        console.log("WETH:", address(weth));
        console.log("Uniswap Factory:", address(factory));
        console.log("Uniswap Router:", address(router));
        console.log("WETH/CCIP-BnM Pair:", pair);
        console.log("PlanStore:", address(existingPlanStore));
        console.log("BundleExecutor:", address(bundleExecutor));
        console.log("CCIP-BnM Token:", ETHEREUM_CCIP_BNM);
        console.log("\nNOTE: Remember to call bundleExecutor.setRemoteExecutor() after deploying RemoteExecutor on Arbitrum");
    }
} 
 