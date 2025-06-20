/**
 * Local test for Chainlink Functions arbitrage analysis
 * This script simulates the Functions environment to test our JavaScript code
 */

const https = require('https');

// Mock Functions environment
global.Functions = {
    makeHttpRequest: async (config) => {
        return new Promise((resolve, reject) => {
            const data = JSON.stringify(config.data);
            
            const options = {
                hostname: new URL(config.url).hostname,
                port: 443,
                path: new URL(config.url).pathname,
                method: config.method,
                headers: {
                    'Content-Type': 'application/json',
                    'Content-Length': data.length,
                    ...config.headers
                }
            };

            const req = https.request(options, (res) => {
                let responseData = '';
                
                res.on('data', (chunk) => {
                    responseData += chunk;
                });
                
                res.on('end', () => {
                    try {
                        const parsedData = JSON.parse(responseData);
                        resolve({ data: parsedData });
                    } catch (error) {
                        resolve({ error: `Parse error: ${error.message}` });
                    }
                });
            });

            req.on('error', (error) => {
                resolve({ error: error.message });
            });

            req.write(data);
            req.end();
        });
    },
    
    encodeString: (types, values) => {
        // Mock ABI encoding - in real Functions this would be proper ABI encoding
        return JSON.stringify({ types, values });
    }
};

// Real deployed pair addresses
global.args = [
    "0xD43E97984d9faD6d41cb901b81b3403A1e7005Fb", // Ethereum Sepolia WETH/CCIP-BnM pair
    "0x7DCA1D3AcAcdA7cDdCAD345FB1CDC6109787914F"  // Arbitrum Sepolia WETH/CCIP-BnM pair
];

// Mock secrets
global.secrets = {
    anthropicApiKey: "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"
};

// Load and execute the Functions code
const fs = require('fs');
const functionsCode = fs.readFileSync('./chainlink-functions/arbitrage-functions.js', 'utf8');

// Create a mock RPC response for getReserves
function mockRpcResponse(pairAddress) {
    // Mock reserves data - getReserves() returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast)
    if (pairAddress === args[0]) { // Ethereum
        // 1 WETH : 40 CCIP-BnM (lower price)
        const reserve0 = BigInt(1e18).toString(16).padStart(64, '0'); // 1 WETH
        const reserve1 = BigInt(40e18).toString(16).padStart(64, '0'); // 40 CCIP-BnM
        const timestamp = Math.floor(Date.now() / 1000).toString(16).padStart(64, '0');
        return "0x" + reserve0 + reserve1 + timestamp;
    } else { // Arbitrum
        // 0.8 WETH : 40 CCIP-BnM (higher price - 1 WETH = 50 CCIP-BnM)
        const reserve0 = BigInt(0.8e18).toString(16).padStart(64, '0'); // 0.8 WETH
        const reserve1 = BigInt(40e18).toString(16).padStart(64, '0'); // 40 CCIP-BnM
        const timestamp = Math.floor(Date.now() / 1000).toString(16).padStart(64, '0');
        return "0x" + reserve0 + reserve1 + timestamp;
    }
}

// Use real RPC calls - no mocking needed for actual deployed contracts

// Execute the Functions code
console.log("🚀 Testing Chainlink Functions with REAL deployed contracts...");
console.log("📊 Real Deployed Addresses:");
console.log("- Ethereum Sepolia Pair:", args[0]);
console.log("- Arbitrum Sepolia Pair:", args[1]);
console.log("- Fetching real reserves from deployed contracts...");
console.log("- Querying real gas prices from both networks...");
console.log("- Using Anthropic LLM for decision making...");
console.log("\n" + "=".repeat(50));

async function testFunctions() {
    try {
        // Execute the Functions code
        const result = await eval(`(async () => { ${functionsCode} })()`);
        
        console.log("\n📋 Functions Result:");
        if (result) {
            console.log("✅ Execution approved!");
            console.log("📦 Encoded result:", result);
            
            // Try to parse the result
            try {
                const parsed = JSON.parse(result);
                console.log("📊 Parsed result:", parsed);
            } catch (e) {
                console.log("📝 Raw result:", result);
            }
        } else {
            console.log("❌ Execution rejected or failed");
        }
        
    } catch (error) {
        console.error("💥 Error testing Functions:", error);
        console.error("Stack:", error.stack);
    }
}

testFunctions(); 
