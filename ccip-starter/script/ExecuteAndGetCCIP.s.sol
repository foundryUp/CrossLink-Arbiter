// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {BundleExecutor} from "../src/BundleExecutor.sol";
import {PlanStore} from "../src/PlanStore.sol";
import {ArbitrageFunctionsConsumer} from "../src/ArbitrageFunctionsConsumer.sol";
import {MockWETH} from "../src/mocks/MockTokens.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ExecuteAndGetCCIP is Script {
    // Current deployment addresses
    address constant BUNDLE_EXECUTOR = 0x9b2a205d2E48ED34AA4c9756E3BBc540Ff6c74cd;
    address constant PLAN_STORE = 0x1177D6F59e9877D6477743C6961988D86ee78174;
    address constant WETH = 0x9871314Bd78FE5191Cfa2145f2aFe1843624475A;
    address constant CCIP_BNM = 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05;
    address constant FUNCTIONS_CONSUMER = 0x2eEbcC4807A0a8C95610E764369D0eeCEC5a655f;
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== EXECUTE ARBITRAGE AND GET CCIP HASH ===");
        
        BundleExecutor bundleExecutor = BundleExecutor(payable(BUNDLE_EXECUTOR));
        PlanStore planStore = PlanStore(PLAN_STORE);
        MockWETH weth = MockWETH(WETH);
        IERC20 ccipBnM = IERC20(CCIP_BNM);
        
        // Check current status
        console.log("Current plan should execute:", planStore.shouldExecute());
        (bool upkeepNeeded,) = bundleExecutor.checkUpkeep("");
        console.log("Upkeep needed:", upkeepNeeded);
        
        // Check balances
        console.log("BundleExecutor WETH:", weth.balanceOf(BUNDLE_EXECUTOR));
        console.log("BundleExecutor CCIP-BnM:", ccipBnM.balanceOf(BUNDLE_EXECUTOR));
        
        // Verify configuration
        console.log("Remote Executor:", bundleExecutor.remoteExecutor());
        console.log("Expected: 0xE6C31609f971A928BB6C98Ca81A01E2930496137");
        
        if (!planStore.shouldExecute()) {
            console.log("\n=== NO ACTIVE PLAN - STORING TEST PLAN ===");
            ArbitrageFunctionsConsumer(FUNCTIONS_CONSUMER).storeTestPlan();
            console.log("Fresh test plan stored via Functions Consumer");
            
            // Check again
            (upkeepNeeded,) = bundleExecutor.checkUpkeep("");
            console.log("Upkeep needed after storing plan:", upkeepNeeded);
        }
        
        if (upkeepNeeded && planStore.shouldExecute()) {
            console.log("\n=== EXECUTING ARBITRAGE ===");
            console.log("Conditions met - triggering performUpkeep...");
            
            uint256 wethBefore = weth.balanceOf(BUNDLE_EXECUTOR);
            uint256 ccipBnMBefore = ccipBnM.balanceOf(BUNDLE_EXECUTOR);
            
            try bundleExecutor.performUpkeep("") {
                console.log("[SUCCESS] performUpkeep executed!");
                
                uint256 wethAfter = weth.balanceOf(BUNDLE_EXECUTOR);
                uint256 ccipBnMAfter = ccipBnM.balanceOf(BUNDLE_EXECUTOR);
                
                console.log("WETH balance change:", wethBefore, "->", wethAfter);
                console.log("CCIP-BnM balance change:", ccipBnMBefore, "->", ccipBnMAfter);
                console.log("Plan cleared:", !planStore.shouldExecute());
                
                console.log("\n=== CCIP MESSAGE SENT ===");
                console.log("Transaction contains CCIP events!");
                console.log("Destination: Arbitrum Sepolia");
                console.log("Receiver:", bundleExecutor.remoteExecutor());
                console.log("Check CCIP Explorer: https://ccip.chain.link/");
                
            } catch Error(string memory reason) {
                console.log("[FAILED] Execution failed:", reason);
                
                if (keccak256(bytes(reason)) == keccak256(bytes("CCIPSendFailed()"))) {
                    console.log("CCIP send failed - likely insufficient LINK for fees");
                    console.log("Required: ~0.04 LINK for CCIP fees");
                    console.log("Current LINK balance:", IERC20(0x779877A7B0D9E8603169DdbD7836e478b4624789).balanceOf(BUNDLE_EXECUTOR));
                }
            }
        } else {
            console.log("[INFO] Automation conditions not met");
            if (!planStore.shouldExecute()) {
                console.log("- No active plan (expired or cleared)");
            }
            if (weth.balanceOf(BUNDLE_EXECUTOR) < 1 ether) {
                console.log("- Insufficient WETH balance (need >= 1 WETH)");
            }
            console.log("- Current gas price might exceed 50 gwei limit");
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== SUMMARY ===");
        console.log("BundleExecutor:", BUNDLE_EXECUTOR);
        console.log("Remote Executor:", bundleExecutor.remoteExecutor());
        console.log("To see CCIP logs:");
        console.log("1. Check transaction receipt for events");
        console.log("2. Visit CCIP Explorer: https://ccip.chain.link/");
        console.log("3. Look for messages to:", bundleExecutor.remoteExecutor());
    }
} 
