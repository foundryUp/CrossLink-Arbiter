// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {MockWETH} from "../src/mocks/MockTokens.sol";
import {MockUniswapV2Router02} from "../src/mocks/MockUniswapV2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SetupLiquidity is Script {
    // Updated deployed addresses
    address constant WETH = 0x9871314Bd78FE5191Cfa2145f2aFe1843624475A;
    address constant CCIP_BNM = 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05;
    address constant ROUTER = 0x64cbCe9cd7Fef7A66a4a4194b1C3F498dF134Efa;
    address constant BUNDLE_EXECUTOR = 0x9b2a205d2E48ED34AA4c9756E3BBc540Ff6c74cd;
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Setting up liquidity...");
        console.log("Deployer:", deployer);
        
        MockWETH weth = MockWETH(WETH);
        IERC20 ccipBnm = IERC20(CCIP_BNM);
        MockUniswapV2Router02 router = MockUniswapV2Router02(ROUTER);
        
        // Mint tokens
        weth.mint(deployer, 100 ether);
        console.log("Minted 100 WETH to deployer");
        
        // Get CCIP-BnM from faucet
        console.log("CCIP-BnM balance:", ccipBnm.balanceOf(deployer));
        
        // Fund BundleExecutor with WETH for testing
        weth.mint(BUNDLE_EXECUTOR, 10 ether);
        console.log("Minted 10 WETH to BundleExecutor");
        
        // Approve router
        weth.approve(ROUTER, 50 ether);
        ccipBnm.approve(ROUTER, ccipBnm.balanceOf(deployer));
        
        // Add liquidity (if we have CCIP-BnM)
        if (ccipBnm.balanceOf(deployer) > 0) {
            router.addLiquidity(
                WETH,
                CCIP_BNM,
                50 ether,  // 50 WETH
                ccipBnm.balanceOf(deployer), // All CCIP-BnM
                45 ether,  // Min WETH
                ccipBnm.balanceOf(deployer) * 9 / 10, // Min CCIP-BnM (90%)
                deployer,
                block.timestamp + 300
            );
            console.log("Liquidity added successfully");
        } else {
            console.log("No CCIP-BnM balance - please get tokens from faucet first");
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== Final Balances ===");
        console.log("WETH balance:", weth.balanceOf(deployer));
        console.log("CCIP-BnM balance:", ccipBnm.balanceOf(deployer));
        console.log("BundleExecutor WETH:", weth.balanceOf(BUNDLE_EXECUTOR));
    }
} 
