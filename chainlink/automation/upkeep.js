// Chainlink Automation Upkeep Configuration - Hackathon Version
// Monitors for execution conditions and triggers arbitrage

const { ethers } = require('ethers');

// Simplified upkeep configuration for hackathon
const upkeepConfig = {
  name: "Cross-Chain Arbitrage Bot",
  checkData: "0x",
  gasLimit: 500000,
  upkeepContract: process.env.BUNDLE_BUILDER_ARBITRUM, // To be set after deployment
  adminAddress: process.env.ADMIN_ADDRESS,
  source: process.env.PRIVATE_KEY, // Funding source
  amount: ethers.utils.parseEther("5") // 5 LINK for upkeep
};

// Register upkeep function
async function registerUpkeep() {
  console.log("🔧 Registering Chainlink Automation upkeep...");
  
  try {
    // Connect to Arbitrum
    const provider = new ethers.providers.JsonRpcProvider(process.env.ARBITRUM_RPC_URL);
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
    
    // Automation Registry contract (Arbitrum Sepolia)
    const registryAddress = "0x86EFBD0b6AfA2960F8a99a7B5E117c25fCf1E8e2";
    const registryABI = [
      "function registerUpkeep(tuple(string name, bytes encryptedEmail, address upkeepContract, uint32 gasLimit, address adminAddress, bytes checkData, bytes offchainConfig, uint96 amount, uint8 source) requestParams) external returns (uint256 id)"
    ];
    
    const registry = new ethers.Contract(registryAddress, registryABI, wallet);
    
    // Register the upkeep
    const tx = await registry.registerUpkeep({
      name: upkeepConfig.name,
      encryptedEmail: "0x", // Empty for hackathon
      upkeepContract: upkeepConfig.upkeepContract,
      gasLimit: upkeepConfig.gasLimit,
      adminAddress: upkeepConfig.adminAddress,
      checkData: upkeepConfig.checkData,
      offchainConfig: "0x", // Empty for hackathon
      amount: upkeepConfig.amount,
      source: 0 // LINK transfer
    });
    
    console.log("📝 Upkeep registration transaction:", tx.hash);
    
    const receipt = await tx.wait();
    console.log("✅ Upkeep registered successfully!");
    console.log("📊 Gas used:", receipt.gasUsed.toString());
    
    // Extract upkeep ID from logs
    const upkeepId = receipt.logs[0].topics[1];
    console.log("🆔 Upkeep ID:", upkeepId);
    
    return upkeepId;
    
  } catch (error) {
    console.error("❌ Error registering upkeep:", error);
    throw error;
  }
}

// Simplified checkUpkeep logic (for reference)
const checkUpkeepLogic = `
// This logic would be implemented in the BundleBuilder contract

function checkUpkeep(bytes calldata checkData) 
  external 
  view 
  override 
  returns (bool upkeepNeeded, bytes memory performData) 
{
    // SIMPLIFIED LOGIC FOR HACKATHON
    
    // Check if there are approved plans ready for execution
    uint256 currentTime = block.timestamp;
    
    // Look for plans with:
    // 1. Status = 'approved'
    // 2. Deadline > current time
    // 3. Minimum profit threshold met
    
    // In a real implementation, this would:
    // - Query the plan storage
    // - Check current prices via Data Streams
    // - Validate execution conditions
    // - Return the best plan to execute
    
    // For hackathon, we'll simulate this:
    bool hasApprovedPlans = true; // Simplified check
    
    if (hasApprovedPlans) {
        upkeepNeeded = true;
        performData = abi.encode("EXECUTE_BEST_PLAN");
    } else {
        upkeepNeeded = false;
        performData = "";
    }
}
`;

// Simplified performUpkeep logic (for reference)
const performUpkeepLogic = `
function performUpkeep(bytes calldata performData) external override {
    // SIMPLIFIED LOGIC FOR HACKATHON
    
    // Decode the perform data
    string memory action = abi.decode(performData, (string));
    
    if (keccak256(bytes(action)) == keccak256(bytes("EXECUTE_BEST_PLAN"))) {
        // Get the best approved plan
        uint256 bestPlanId = getBestApprovedPlan();
        
        if (bestPlanId > 0) {
            // Execute the arbitrage plan
            executePlan(bestPlanId);
            
            emit UpkeepPerformed(bestPlanId, block.timestamp);
        }
    }
}
`;

// Monitoring function for upkeep status
async function monitorUpkeep(upkeepId) {
  console.log(`📊 Monitoring upkeep ${upkeepId}...`);
  
  try {
    const provider = new ethers.providers.JsonRpcProvider(process.env.ARBITRUM_RPC_URL);
    
    // Registry contract for querying upkeep info
    const registryABI = [
      "function getUpkeep(uint256 id) external view returns (tuple(address target, uint32 executeGas, bytes checkData, uint96 balance, address admin, uint64 maxValidBlocknumber, uint32 lastPerformBlockNumber, uint96 amountSpent, bool paused, bytes offchainConfig))"
    ];
    
    const registry = new ethers.Contract(
      "0x86EFBD0b6AfA2960F8a99a7B5E117c25fCf1E8e2", 
      registryABI, 
      provider
    );
    
    setInterval(async () => {
      try {
        const upkeepInfo = await registry.getUpkeep(upkeepId);
        
        console.log("📈 Upkeep Status:");
        console.log("  Balance:", ethers.utils.formatEther(upkeepInfo.balance), "LINK");
        console.log("  Last Perform Block:", upkeepInfo.lastPerformBlockNumber.toString());
        console.log("  Amount Spent:", ethers.utils.formatEther(upkeepInfo.amountSpent), "LINK");
        console.log("  Paused:", upkeepInfo.paused);
        
      } catch (error) {
        console.error("Error fetching upkeep info:", error.message);
      }
    }, 30000); // Check every 30 seconds
    
  } catch (error) {
    console.error("❌ Error monitoring upkeep:", error);
  }
}

// Main execution function
async function main() {
  const action = process.argv[2];
  
  switch (action) {
    case 'register':
      await registerUpkeep();
      break;
      
    case 'monitor':
      const upkeepId = process.argv[3];
      if (!upkeepId) {
        console.error("Please provide upkeep ID for monitoring");
        process.exit(1);
      }
      await monitorUpkeep(upkeepId);
      break;
      
    default:
      console.log("Usage:");
      console.log("  node upkeep.js register    - Register new upkeep");
      console.log("  node upkeep.js monitor <id> - Monitor existing upkeep");
  }
}

// Export for use in other scripts
module.exports = {
  registerUpkeep,
  monitorUpkeep,
  upkeepConfig,
  checkUpkeepLogic,
  performUpkeepLogic
};

// Run if called directly
if (require.main === module) {
  main().catch(console.error);
} 