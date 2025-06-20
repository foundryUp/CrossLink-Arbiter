// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";

interface ICCIP_BnM {
    function drip(address to) external;
    function balanceOf(address account) external view returns (uint256);
}

contract GetCCIPTokens is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Get CCIP-BnM tokens on both chains
        if (block.chainid == 11155111) { // Ethereum Sepolia
            address ccipBnM = 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05;
            console.log("Getting CCIP-BnM tokens on Ethereum Sepolia...");
            
            // Request multiple drips to get enough tokens
            for (uint i = 0; i < 50; i++) {
                ICCIP_BnM(ccipBnM).drip(deployer);
            }
            
            uint256 balance = ICCIP_BnM(ccipBnM).balanceOf(deployer);
            console.log("CCIP-BnM balance:", balance);
            
        } else if (block.chainid == 421614) { // Arbitrum Sepolia  
            address ccipBnM = 0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D;
            console.log("Getting CCIP-BnM tokens on Arbitrum Sepolia...");
            
            // Request multiple drips to get enough tokens
            for (uint i = 0; i < 50; i++) {
                ICCIP_BnM(ccipBnM).drip(deployer);
            }
            
            uint256 balance = ICCIP_BnM(ccipBnM).balanceOf(deployer);
            console.log("CCIP-BnM balance:", balance);
        }
        
        vm.stopBroadcast();
    }
} 
