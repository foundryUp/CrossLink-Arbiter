// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/ArbitrageFunctionsConsumer.sol";

/**
 * @title Deploy ArbitrageFunctionsConsumer
 * @notice Deploys the Functions Consumer for cross-chain arbitrage
 */
contract DeployArbitrageFunctionsConsumer is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address planStore = 0x1177D6F59e9877D6477743C6961988D86ee78174;

        
        // Deploy ArbitrageFunctionsConsumer
        ArbitrageFunctionsConsumer consumer = new ArbitrageFunctionsConsumer(planStore);
        
        console.log("=== DEPLOYMENT SUCCESSFUL ===");
        console.log("ArbitrageFunctionsConsumer deployed at:", address(consumer));
        console.log("   https://functions.chain.link/sepolia/5056");
        
        vm.stopBroadcast();
    }
} 
 