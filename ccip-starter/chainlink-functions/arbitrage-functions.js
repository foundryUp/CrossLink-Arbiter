/**
 * Chainlink Functions JavaScript Code for Cross-Chain Arbitrage Analysis
 * 
 * This function:
 * 1. Fetches WETH/CCIP-BnM reserves from Uniswap V2 pools on both Ethereum and Arbitrum Sepolia
 * 2. Calculates price differences and arbitrage opportunities
 * 3. Retrieves current gas prices
 * 4. Queries Anthropic LLM for execution decision
 * 5. Returns ABI-encoded arbitrage plan or null
 */

// RPC URLs for both chains
const ETHEREUM_SEPOLIA_RPC = "https://eth-sepolia.g.alchemy.com/v2/xiJw6cj_7U8PXLSncrSON78PWDXP4Dkl";
const ARBITRUM_SEPOLIA_RPC = "https://arb-sepolia.g.alchemy.com/v2/xiJw6cj_7U8PXLSncrSON78PWDXP4Dkl";

// Pool pair addresses - these will be set from function arguments
// In production, these would be passed as args from the calling contract
const ETHEREUM_WETH_CCIPBNM_PAIR = args[0]; // First argument: Ethereum pair address  
const ARBITRUM_WETH_CCIPBNM_PAIR = args[1]; // Second argument: Arbitrum pair address

// Validate arguments
if (!ETHEREUM_WETH_CCIPBNM_PAIR || !ARBITRUM_WETH_CCIPBNM_PAIR) {
    throw new Error("Missing required arguments: pair addresses");
}

// Validate Ethereum addresses (basic check)
function isValidEthereumAddress(address) {
    return /^0x[a-fA-F0-9]{40}$/.test(address);
}

if (!isValidEthereumAddress(ETHEREUM_WETH_CCIPBNM_PAIR)) {
    throw new Error(`Invalid Ethereum pair address: ${ETHEREUM_WETH_CCIPBNM_PAIR}`);
}

if (!isValidEthereumAddress(ARBITRUM_WETH_CCIPBNM_PAIR)) {
    throw new Error(`Invalid Arbitrum pair address: ${ARBITRUM_WETH_CCIPBNM_PAIR}`);
}

// Anthropic API configuration
const ANTHROPIC_API_KEY = "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";
const ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages";

// ABI for getReserves function
const GET_RESERVES_ABI = "0x0902f1ac"; // getReserves() function selector

/**
 * Makes an RPC call to get contract data
 */
async function makeRpcCall(rpcUrl, contractAddress, data) {
    const response = await Functions.makeHttpRequest({
        url: rpcUrl,
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        data: {
            jsonrpc: "2.0",
            method: "eth_call",
            params: [
                {
                    to: contractAddress,
                    data: data,
                },
                "latest"
            ],
            id: 1,
        },
    });

    if (response.error) {
        throw new Error(`RPC call failed: ${response.error}`);
    }

    return response.data.result;
}

/**
 * Gets gas price from a chain
 */
async function getGasPrice(rpcUrl) {
    const response = await Functions.makeHttpRequest({
        url: rpcUrl,
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        data: {
            jsonrpc: "2.0",
            method: "eth_gasPrice",
            params: [],
            id: 1,
        },
    });

    if (response.error) {
        throw new Error(`Gas price call failed: ${response.error}`);
    }

    return BigInt(response.data.result);
}

/**
 * Decodes Uniswap V2 getReserves response
 */
function decodeReserves(data) {
    // Remove 0x prefix and decode hex
    const hex = data.startsWith('0x') ? data.slice(2) : data;
    
    // Each uint112 is 32 bytes (padded), uint32 is 32 bytes (padded)
    const reserve0Hex = hex.slice(0, 64);
    const reserve1Hex = hex.slice(64, 128);
    const timestampHex = hex.slice(128, 192);
    
    return {
        reserve0: BigInt("0x" + reserve0Hex),
        reserve1: BigInt("0x" + reserve1Hex),
        blockTimestampLast: parseInt("0x" + timestampHex, 16)
    };
}

/**
 * Calculates price based on reserves (CCIP-BnM per WETH)
 */
function calculatePrice(reserve0, reserve1, token0IsWETH) {
    // Validate reserves are not zero
    if (reserve0 === 0n || reserve1 === 0n) {
        throw new Error("Pool has no liquidity - one or both reserves are zero");
    }
    
    // Convert BigInt to Number for decimal division
    const reserve0Num = Number(reserve0);
    const reserve1Num = Number(reserve1);
    
    if (token0IsWETH) {
        // WETH is token0, CCIP-BnM is token1
        // Price = CCIP-BnM/WETH = reserve1/reserve0
        return reserve1Num / reserve0Num;
    } else {
        // CCIP-BnM is token0, WETH is token1
        // Price = CCIP-BnM/WETH = reserve0/reserve1
        return reserve0Num / reserve1Num;
    }
}

/**
 * Queries Anthropic LLM for arbitrage decision
 */
async function queryAnthropicLLM(prompt) {
    console.log("Making Anthropic API call...");
    
    const response = await Functions.makeHttpRequest({
        url: ANTHROPIC_API_URL,
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            "x-api-key": ANTHROPIC_API_KEY,
            "anthropic-version": "2023-06-01"
        },
        data: {
            model: "claude-3-5-sonnet-20241022",
            max_tokens: 1000,
            messages: [
                {
                    role: "user",
                    content: prompt
                }
            ]
        },
    });

    console.log("Anthropic response received:", JSON.stringify(response, null, 2));

    if (response.error) {
        throw new Error(`Anthropic API call failed: ${response.error}`);
    }

    // Handle the response structure properly
    if (response.data && response.data.content && Array.isArray(response.data.content) && response.data.content.length > 0) {
        return response.data.content[0].text;
    } else {
        throw new Error(`Unexpected response structure: ${JSON.stringify(response)}`);
    }
}

/**
 * Main function execution
 */
async function main() {
    try {
        // 1. Fetch reserves from both chains
        console.log("Fetching reserves from both chains...");
        
        const [ethReservesData, arbReservesData] = await Promise.all([
            makeRpcCall(ETHEREUM_SEPOLIA_RPC, ETHEREUM_WETH_CCIPBNM_PAIR, GET_RESERVES_ABI),
            makeRpcCall(ARBITRUM_SEPOLIA_RPC, ARBITRUM_WETH_CCIPBNM_PAIR, GET_RESERVES_ABI)
        ]);

        const ethReserves = decodeReserves(ethReservesData);
        const arbReserves = decodeReserves(arbReservesData);

        // 2. Calculate prices (assuming WETH is token0 on both chains)
        const ethPrice = calculatePrice(ethReserves.reserve0, ethReserves.reserve1, true);
        const arbPrice = calculatePrice(arbReserves.reserve0, arbReserves.reserve1, true);

        // Log the actual prices for debugging
        console.log("=== PRICE ANALYSIS ===");
        console.log("Ethereum WETH/CCIP-BnM reserves:", ethReserves.reserve0.toString(), "/", ethReserves.reserve1.toString());
        console.log("Arbitrum WETH/CCIP-BnM reserves:", arbReserves.reserve0.toString(), "/", arbReserves.reserve1.toString());
        console.log("Ethereum price (CCIP-BnM per WETH):", Number(ethPrice).toFixed(6));
        console.log("Arbitrum price (CCIP-BnM per WETH):", Number(arbPrice).toFixed(6));

        // 3. Calculate edge in basis points
        const edgeBps = arbPrice > ethPrice 
            ? ((arbPrice - ethPrice) * 10000) / ethPrice
            : ((ethPrice - arbPrice) * 10000) / arbPrice;
        
        // Validate edge calculation didn't result in division by zero
        if (!isFinite(edgeBps)) {
            throw new Error("Invalid price data - unable to calculate arbitrage edge");
        }
        
        console.log("Price difference (basis points):", edgeBps);
        console.log("======================");

        // 4. Get gas prices
        const [ethGasPrice, arbGasPrice] = await Promise.all([
            getGasPrice(ETHEREUM_SEPOLIA_RPC),
            getGasPrice(ARBITRUM_SEPOLIA_RPC)
        ]);

        const ethGasGwei = Number(ethGasPrice) / 1e9;
        const arbGasGwei = Number(arbGasPrice) / 1e9;

        // 5. Prepare LLM prompt
        const prompt = `
You are a cross-chain arbitrage analysis system. Based on the following market data, decide whether to execute an arbitrage trade:

MARKET DATA:
- Ethereum Sepolia WETH/CCIP-BnM price: ${Number(ethPrice) / 1e18} CCIP-BnM per WETH
- Arbitrum Sepolia WETH/CCIP-BnM price: ${Number(arbPrice) / 1e18} CCIP-BnM per WETH
- Price difference: ${edgeBps} basis points
- Ethereum gas price: ${ethGasGwei} gwei
- Arbitrum gas price: ${arbGasGwei} gwei

ARBITRAGE STRATEGY:
- Buy WETH with CCIP-BnM on the cheaper chain
- Send CCIP-BnM cross-chain via Chainlink CCIP
- Sell CCIP-BnM for WETH on the more expensive chain
- Profit = difference in WETH prices minus gas costs

DECISION CRITERIA:
- Minimum profitable edge: 50 basis points (0.5%)
- Maximum gas price: 50 gwei
- Suggested trade size: 1-10 WETH based on edge size and liquidity

REQUIRED RESPONSE FORMAT (JSON only, no explanation):
{
  "execute": true/false,
  "amount": "amount_in_wei_as_string",
  "minEdgeBps": minimum_edge_threshold,
  "maxGasGwei": maximum_gas_threshold
}

If execute is true, provide the exact amount in wei (as string) and thresholds.
If execute is false, set amount to "0".
`;

        // 6. Query LLM
        console.log("Querying Anthropic LLM for arbitrage decision...");
        const llmResponse = await queryAnthropicLLM(prompt);
        
        // 7. Parse LLM response
        let decision;
        try {
            // Extract JSON from response (in case there's extra text)
            let responseText = llmResponse;
            
            // Handle different response formats
            if (typeof llmResponse === 'object' && llmResponse.content) {
                if (Array.isArray(llmResponse.content) && llmResponse.content.length > 0) {
                    responseText = llmResponse.content[0].text;
                } else if (typeof llmResponse.content === 'string') {
                    responseText = llmResponse.content;
                }
            }
            
            console.log("LLM Response:", responseText);
            
            const jsonMatch = responseText.match(/\{[\s\S]*\}/);
            if (!jsonMatch) {
                throw new Error("No JSON found in response");
            }
            decision = JSON.parse(jsonMatch[0]);
        } catch (parseError) {
            console.error("Failed to parse LLM response:", llmResponse);
            throw new Error(`LLM response parsing failed: ${parseError.message}`);
        }

        // 8. Validate decision structure
        if (typeof decision.execute !== 'boolean' || 
            typeof decision.amount !== 'string' ||
            typeof decision.minEdgeBps !== 'number' ||
            typeof decision.maxGasGwei !== 'number') {
            throw new Error("Invalid decision structure from LLM");
        }

        // 9. Return result
        if (decision.execute) {
            console.log(`Arbitrage approved: ${decision.amount} wei, edge: ${edgeBps} bps`);
            
            // ABI encode the arbitrage plan
            const planData = Functions.encodeString(
                "bool,uint256,uint256,uint256,uint256",
                [
                    decision.execute,
                    decision.amount,
                    decision.minEdgeBps,
                    decision.maxGasGwei,
                    0 // timestamp will be set by contract
                ]
            );
            
            return planData;
        } else {
            console.log("Arbitrage not profitable, returning null");
            return null;
        }

    } catch (error) {
        console.error("Error in arbitrage analysis:", error.message);
        
        // Return null on error to prevent execution
        return null;
    }
}

// Execute main function
return main(); 
 