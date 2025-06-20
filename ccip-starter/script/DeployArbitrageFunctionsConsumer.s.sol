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
        
        // Configuration from previous deployments
        uint64 subscriptionId = 5056; // Your Functions subscription ID
        address planStore = 0x1177D6F59e9877D6477743C6961988D86ee78174; // PlanStore contract
        
        // Pair addresses from liquidity setup
        address ethereumPair = 0xD43E97984d9faD6d41cb901b81b3403A1e7005Fb; // Ethereum WETH/CCIP-BnM pair
        address arbitrumPair = 0x7DCA1D3AcAcdA7cDdCAD345FB1CDC6109787914F; // Arbitrum WETH/CCIP-BnM pair
        
        // Token addresses on each chain
        address ethereumWETH = 0xe95dd35Ef9dCafD0e570D378Fa04527c22A87911; // Ethereum Sepolia WETH
        address ethereumCCIPBnM = 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05; // Ethereum Sepolia CCIP-BnM
        address arbitrumWETH = 0x9BAd0F20eB62a2238c9849A7cE50FCafdE0E1481; // Arbitrum Sepolia WETH
        address arbitrumCCIPBnM = 0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D; // Arbitrum Sepolia CCIP-BnM
        
        console.log("=== DEPLOYING ARBITRAGE FUNCTIONS CONSUMER ===");
        console.log("Subscription ID:", subscriptionId);
        console.log("PlanStore:", planStore);
        console.log("Ethereum Pair:", ethereumPair);
        console.log("Arbitrum Pair:", arbitrumPair);
        console.log("Ethereum WETH:", ethereumWETH);
        console.log("Ethereum CCIP-BnM:", ethereumCCIPBnM);
        console.log("Arbitrum WETH:", arbitrumWETH);
        console.log("Arbitrum CCIP-BnM:", arbitrumCCIPBnM);
        
        // Deploy ArbitrageFunctionsConsumer
        ArbitrageFunctionsConsumer consumer = new ArbitrageFunctionsConsumer(
            subscriptionId,
            planStore,
            ethereumPair,
            arbitrumPair,
            ethereumWETH,
            ethereumCCIPBnM,
            arbitrumWETH,
            arbitrumCCIPBnM
        );
        
        console.log("=== DEPLOYMENT SUCCESSFUL ===");
        console.log("ArbitrageFunctionsConsumer deployed at:", address(consumer));
        console.log("");
        console.log("=== NEXT STEPS ===");
        console.log("1. Add this consumer address to Functions subscription 5056:");
        console.log("   Consumer address:", address(consumer));
        console.log("");
        console.log("2. Test the consumer:");
        console.log("   cast send", address(consumer));
        console.log("   \"manualTrigger()\" --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC");
        console.log("");
        console.log("3. Monitor Functions requests:");
        console.log("   https://functions.chain.link/sepolia/5056");
        
        vm.stopBroadcast();
    }
} 
