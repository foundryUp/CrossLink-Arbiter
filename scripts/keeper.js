// scripts/keeperFlashbotsBot.js

import { ethers } from "ethers";
import { FlashbotsBundleProvider } from "@flashbots/ethers-provider-bundle";

// CONFIGURATION
const RPC_URL = "https://sepolia.infura.io/v3/YOUR_INFURA_KEY"; //  replace with your real key
const FLASHBOTS_URL = "https://relay-sepolia.flashbots.net";
const BUNDLE_EXECUTOR = "0xYourBundleExecutorAddress"; //  replace with deployed address
const PRIVATE_KEY = "0xYOUR_PRIVATE_KEY"; //  wallet with WETH

const BUNDLE_EXECUTOR_ABI = [
  "function performUpkeep(bytes calldata) external",
  "function checkUpkeep(bytes calldata) external view returns (bool, bytes memory)"
];

// INIT
const provider = new ethers.JsonRpcProvider(RPC_URL);
const authSigner = ethers.Wallet.createRandom();
const botSigner = new ethers.Wallet(PRIVATE_KEY, provider);

async function main() {
  const flashbots = await FlashbotsBundleProvider.create(provider, authSigner, FLASHBOTS_URL);
  const executor = new ethers.Contract(BUNDLE_EXECUTOR, BUNDLE_EXECUTOR_ABI, provider);

  console.log("⏳ Checking upkeep status...");
  const [shouldExecute] = await executor.checkUpkeep("0x");
  if (!shouldExecute) {
    console.log("❌ No arbitrage opportunity.");
    return;
  }

  const tx = await executor.connect(botSigner).populateTransaction.performUpkeep("0x");
  const signedTx = await botSigner.signTransaction({
    ...tx,
    gasLimit: 300000n,
    maxFeePerGas: ethers.parseUnits("50", "gwei"),
    maxPriorityFeePerGas: ethers.parseUnits("2", "gwei"),
    nonce: await provider.getTransactionCount(botSigner.address),
    chainId: 11155111
  });

  const block = await provider.getBlockNumber();
  console.log("Sending private bundle to Flashbots...");

  const res = await flashbots.sendBundle(
    [{ signedTransaction: signedTx }],
    block + 1
  );

  const receipt = await res.wait();
  if (receipt === 0) {
    console.log(" Bundle included in block", block + 1);
  } else {
    console.log("Bundle not included.");
  }
}

main().catch(err => {
  console.error("Error in keeper bot:", err);
});
