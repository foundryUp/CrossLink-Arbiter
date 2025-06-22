// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {MockWETH} from "../src/mocks/MockTokens.sol";
import {MockUniswapV2Router02} from "../src/mocks/MockUniswapV2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SetupLiquidity is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Setting up liquidity...");
        console.log("Deployer:", deployer);
        
        _setupTokensAndLiquidity(deployer);
        
        vm.stopBroadcast();
        
        console.log("\n=== Setup Complete ===");
    }
    
    function _setupTokensAndLiquidity(address deployer) internal {
        // Get addresses from environment variables
        address weth = vm.envAddress("WETH_ADDRESS");
        address ccipBnm = vm.envAddress("CCIP_BNM_ADDRESS");
        address router = vm.envAddress("ROUTER_ADDRESS");
        
        console.log("WETH:", weth);
        console.log("CCIP-BnM:", ccipBnm);
        console.log("Router:", router);
        
        // Mint WETH tokens
        MockWETH(weth).mint(deployer, 100 ether);
        console.log("Minted 100 WETH to deployer");
        
        // Try to get CCIP-BnM from faucet
        (bool success,) = ccipBnm.call(abi.encodeWithSignature("drip(address)", deployer));
        if (success) {
            console.log("Got CCIP-BnM from drip");
        }
        
        uint256 ccipBalance = IERC20(ccipBnm).balanceOf(deployer);
        console.log("CCIP-BnM balance:", ccipBalance);
        
        // Fund BundleExecutor if address is set
        try vm.envAddress("BUNDLE_EXECUTOR_ADDRESS") returns (address bundleExecutor) {
            MockWETH(weth).mint(bundleExecutor, 10 ether);
            console.log("Minted 10 WETH to BundleExecutor");
        } catch {
            console.log("No BundleExecutor address set");
        }
        
        // Add liquidity if we have tokens
        if (ccipBalance > 0) {
            _addLiquidity(deployer, weth, ccipBnm, router, ccipBalance);
        } else {
            console.log("No CCIP-BnM balance - get tokens from faucet first");
        }
    }
    
    function _addLiquidity(
        address deployer, 
        address weth, 
        address ccipBnm, 
        address router,
        uint256 ccipBalance
    ) internal {
        // Approve tokens
        IERC20(weth).approve(router, 50 ether);
        IERC20(ccipBnm).approve(router, ccipBalance);
        
        // Add liquidity
        MockUniswapV2Router02(router).addLiquidity(
            weth,
            ccipBnm,
            50 ether,  // 50 WETH
            ccipBalance, // All CCIP-BnM
            45 ether,  // Min WETH
            ccipBalance * 9 / 10, // Min CCIP-BnM (90%)
            deployer,
            block.timestamp + 300
        );
        console.log("Liquidity added successfully");
    }
} 
 