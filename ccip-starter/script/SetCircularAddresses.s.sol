// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {BundleExecutor} from "../src/BundleExecutor.sol";
import {RemoteExecutor} from "../src/RemoteExecutor.sol";

contract SetCircularAddresses is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address bundleExecutorAddress = vm.envAddress("BUNDLE_EXECUTOR_ADDRESS");
        address remoteExecutorAddress = vm.envAddress("REMOTE_EXECUTOR_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Setting circular addresses...");
        console.log("BundleExecutor:", bundleExecutorAddress);
        console.log("RemoteExecutor:", remoteExecutorAddress);
        
        // Set remote executor in BundleExecutor (on Ethereum)
        BundleExecutor bundleExecutor = BundleExecutor(payable(bundleExecutorAddress));
        bundleExecutor.setRemoteExecutor(remoteExecutorAddress);
        console.log("SUCCESS: RemoteExecutor address set in BundleExecutor");
        
        vm.stopBroadcast();
        
        console.log("\n=== Configuration Complete ===");
        console.log("BundleExecutor now knows RemoteExecutor at:", remoteExecutorAddress);
        console.log("\nNext: Run SetAuthorizedSender script on Arbitrum to complete the setup");
    }
}

contract SetAuthorizedSender is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address bundleExecutorAddress = vm.envAddress("BUNDLE_EXECUTOR_ADDRESS");
        address remoteExecutorAddress = vm.envAddress("REMOTE_EXECUTOR_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Setting authorized sender...");
        console.log("BundleExecutor:", bundleExecutorAddress);
        console.log("RemoteExecutor:", remoteExecutorAddress);
        
        // Set authorized sender in RemoteExecutor (on Arbitrum)
        RemoteExecutor remoteExecutor = RemoteExecutor(payable(remoteExecutorAddress));
        remoteExecutor.setAuthorizedSender(bundleExecutorAddress);
        console.log("SUCCESS: BundleExecutor authorized in RemoteExecutor");
        
        vm.stopBroadcast();
        
        console.log("\n=== Configuration Complete ===");
        console.log("RemoteExecutor now accepts messages from BundleExecutor at:", bundleExecutorAddress);
        console.log("\nSUCCESS: Circular dependency resolved! Both contracts are fully configured.");
    }
} 
