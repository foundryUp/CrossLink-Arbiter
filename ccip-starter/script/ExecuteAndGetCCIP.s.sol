// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {BundleExecutor} from "../src/BundleExecutor.sol";
import {PlanStore} from "../src/PlanStore.sol";
import {ArbitrageFunctionsConsumer} from "../src/ArbitrageFunctionsConsumer.sol";
import {MockWETH} from "../src/mocks/MockTokens.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Vm} from "forge-std/Vm.sol";

contract ExecuteAndGetCCIP is Script {
    // UPDATED deployment addresses from NEW deployment with circular dependency fix
    address constant BUNDLE_EXECUTOR = 0xB20412c4403277A6dD64e0D0dCa19F81b5412cBA;
    address constant PLAN_STORE = 0x1177D6F59e9877D6477743C6961988D86ee78174;
    address constant WETH = 0xe95595f0BE77d6CF079795Ed63942933E9a6bf7b;
    address constant CCIP_BNM = 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05;
    address constant FUNCTIONS_CONSUMER = 0x2eEbcC4807A0a8C95610E764369D0eeCEC5a655f;
    address constant CCIP_ROUTER = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59; // Ethereum Sepolia CCIP Router
    
    // CCIP Message Sent event signature
    event CCIPSendRequested(bytes32 indexed messageId);
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== EXECUTE ARBITRAGE AND GET CCIP HASH ===");
        console.log("NEW BundleExecutor with Circular Dependency Fix!");
        
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
        console.log("BundleExecutor LINK:", IERC20(0x779877A7B0D9E8603169DdbD7836e478b4624789).balanceOf(BUNDLE_EXECUTOR));
        
        // Verify NEW configuration (circular dependency fix)
        console.log("Remote Executor:", bundleExecutor.remoteExecutor());
        console.log("Expected: 0x45ee7AA56775aB9385105393458FC4e56b4B578c");
        console.log("Remote Executor Set:", bundleExecutor.remoteExecutorSet());
        
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
            uint256 linkBefore = IERC20(0x779877A7B0D9E8603169DdbD7836e478b4624789).balanceOf(BUNDLE_EXECUTOR);
            
            // Record logs before execution to capture CCIP events
            vm.recordLogs();
            
            try bundleExecutor.performUpkeep("") {
                console.log("[SUCCESS] performUpkeep executed!");
                
                // Get recorded logs to extract CCIP message details
                Vm.Log[] memory logs = vm.getRecordedLogs();
                bytes32 ccipMessageId = bytes32(0);
                bool ccipEventFound = false;
                
                // Look for CCIP message sent events
                for (uint256 i = 0; i < logs.length; i++) {
                    // Check for CCIPSendRequested event from CCIP Router
                    if (logs[i].emitter == CCIP_ROUTER && logs[i].topics.length > 0) {
                        // CCIP Router emits events with message ID
                        if (logs[i].topics[0] == keccak256("CCIPSendRequested(bytes32)")) {
                            ccipMessageId = logs[i].topics[1];
                            ccipEventFound = true;
                            break;
                        }
                        // Alternative: look for general Message events that might contain messageId
                        else if (logs[i].data.length >= 32) {
                            // Try to extract potential message ID from event data
                            bytes memory logData = logs[i].data;
                            bytes32 potentialMessageId;
                            assembly {
                                potentialMessageId := mload(add(logData, 0x20))
                            }
                            if (potentialMessageId != bytes32(0)) {
                                ccipMessageId = potentialMessageId;
                                ccipEventFound = true;
                            }
                        }
                    }
                }
                
                uint256 wethAfter = weth.balanceOf(BUNDLE_EXECUTOR);
                uint256 ccipBnMAfter = ccipBnM.balanceOf(BUNDLE_EXECUTOR);
                uint256 linkAfter = IERC20(0x779877A7B0D9E8603169DdbD7836e478b4624789).balanceOf(BUNDLE_EXECUTOR);
                
                console.log("WETH balance change:", wethBefore, "->", wethAfter);
                console.log("CCIP-BnM balance change:", ccipBnMBefore, "->", ccipBnMAfter);
                console.log("LINK balance change:", linkBefore, "->", linkAfter);
                console.log("Plan cleared:", !planStore.shouldExecute());
                
                console.log("\n=== CCIP MESSAGE DETAILS ===");
                if (ccipEventFound && ccipMessageId != bytes32(0)) {
                    console.log("CCIP Message ID:", vm.toString(ccipMessageId));
                    console.logBytes32(ccipMessageId);
                } else {
                    console.log("CCIP Message ID: Check transaction receipt for CCIPSendRequested event");
                }
                
                console.log("Transaction Hash: Available in transaction receipt");
                console.log("NEW ARCHITECTURE: Circular dependency resolved!");
                console.log("Destination: Arbitrum Sepolia");
                console.log("Receiver:", bundleExecutor.remoteExecutor());
                console.log("CCIP Explorer: https://ccip.chain.link/");
                
                console.log("\n=== HOW TO GET TRANSACTION HASH ===");
                console.log("1. Check the forge output above for 'Transaction hash:'");
                console.log("2. Or use this command after execution:");
                console.log("   cast receipt <transaction_hash> --rpc-url $ETHEREUM_SEPOLIA_RPC_URL");
                console.log("3. Look for 'CCIPSendRequested' or 'MessageSent' events");
                
            } catch Error(string memory reason) {
                console.log("[FAILED] Execution failed:", reason);
                
                if (keccak256(bytes(reason)) == keccak256(bytes("CCIPSendFailed()"))) {
                    console.log("CCIP send failed - likely insufficient LINK for fees");
                    console.log("Required: ~0.04 LINK for CCIP fees");
                    console.log("Current LINK balance:", IERC20(0x779877A7B0D9E8603169DdbD7836e478b4624789).balanceOf(BUNDLE_EXECUTOR));
                }
                
                if (keccak256(bytes(reason)) == keccak256(bytes("RemoteExecutorNotSet()"))) {
                    console.log("RemoteExecutor not set - run SetCircularAddresses script first!");
                }
            }
        } else {
            console.log("[INFO] Automation conditions not met");
            if (!planStore.shouldExecute()) {
                console.log("- No active plan (expired or cleared)");
            }
            if (weth.balanceOf(BUNDLE_EXECUTOR) < 1 ether) {
                console.log("- Insufficient WETH balance (need >= 1 WETH)");
                console.log("- Current WETH:", weth.balanceOf(BUNDLE_EXECUTOR));
            }
            if (!bundleExecutor.remoteExecutorSet()) {
                console.log("- RemoteExecutor not set (circular dependency not resolved)");
            }
            console.log("- Current gas price might exceed 50 gwei limit");
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== SUMMARY ===");
        console.log("NEW BundleExecutor:", BUNDLE_EXECUTOR);
        console.log("NEW Remote Executor:", bundleExecutor.remoteExecutor());
        console.log("Circular Dependency Fixed:", bundleExecutor.remoteExecutorSet());
        console.log("\n=== CCIP MESSAGE TRACKING ===");
        console.log("1. Transaction hash will be shown in forge output above");
        console.log("2. Use: cast receipt <tx_hash> --rpc-url $ETHEREUM_SEPOLIA_RPC_URL");
        console.log("3. Look for CCIPSendRequested event topics[1] = messageId");
        console.log("4. Visit CCIP Explorer: https://ccip.chain.link/");
        console.log("5. Search by message ID or transaction hash");
        console.log("6. NEW: Real RemoteExecutor destination, no more dummy addresses!");
    }
} 
 