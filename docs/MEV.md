### Flashbots Keeper Bot – MEV-Protected Arbitrage Trigger

This script privately triggers your smart contract's `performUpkeep()` function (from `BundleExecutor.sol`) via Flashbots to avoid MEV attacks during arbitrage execution.

---

### How It Works

1. Connects to Sepolia via Infura and Flashbots RPC.
2. Reads `checkUpkeep()` from your deployed `BundleExecutor` contract.
3. If `shouldExecute == true`:
   - Builds and signs a `performUpkeep()` transaction.
   - Sends it as a Flashbots bundle (via `eth_sendBundle`) to protect against front-running and back-running.
4. Awaits confirmation of bundle inclusion.

Docs: [Flashbots RPC Endpoint](https://docs.flashbots.net/flashbots-auction/advanced/rpc-endpoint)

---

### Why Flashbots?

- Prevents mempool visibility (no sandwich/copy bots)
- Keeps arbitrage logic safe and private
- Replaces Chainlink Automation with your own bot

---

### Requirements

Update these values in the script:

```js
const RPC_URL = "https://sepolia.infura.io/v3/YOUR_INFURA_KEY";
const BUNDLE_EXECUTOR = "0xYourBundleExecutorAddress"; // deployed contract address
const PRIVATE_KEY = "0xYOUR_PRIVATE_KEY"; // wallet holding WETH
```

---

### Run It

```bash
npm install ethers @flashbots/ethers-provider-bundle
node scripts/keeperFlashbotsBot.js
```

---

### Output

- "Bundle included" → your `performUpkeep()` was executed safely
- "No arbitrage opportunity" → `checkUpkeep()` returned false
- "Bundle not included" → try again in the next block