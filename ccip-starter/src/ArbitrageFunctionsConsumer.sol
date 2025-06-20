// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {FunctionsClient} from "chainlink-evm/contracts/src/v0.8/functions/v1_3_0/FunctionsClient.sol";
import {ConfirmedOwner} from "chainlink-evm/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "chainlink-evm/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {PlanStore} from "./PlanStore.sol";

/**
 * @title ArbitrageFunctionsConsumer
 * @notice Real Chainlink Functions consumer for cross-chain arbitrage
 * @dev Calls Functions to analyze markets and stores execution plans
 */
contract ArbitrageFunctionsConsumer is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

    // Ethereum Sepolia Functions configuration
    bytes32 public constant DON_ID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;
    uint64 public immutable subscriptionId;
    uint32 public gasLimit = 300_000;
    
    // Contract integrations
    PlanStore public immutable planStore;
    
    // Pair addresses for arbitrage analysis
    address public ethereumPair;
    address public arbitrumPair;
    
    // Token addresses on each chain
    address public ethereumWETH;
    address public ethereumCCIPBnM;
    address public arbitrumWETH;
    address public arbitrumCCIPBnM;
    
    // Request tracking
    mapping(bytes32 => bool) public pendingRequests;
    uint256 public lastRequestTimestamp;
    uint256 public requestCount;
    
    // Events
    event RequestSent(bytes32 indexed requestId, uint256 timestamp);
    event RequestFulfilled(bytes32 indexed requestId, bool planExecute, uint256 amount);
    event RequestFailed(bytes32 indexed requestId, string error);
    event TokenAddressesUpdated(address ethereumWETH, address ethereumCCIPBnM, address arbitrumWETH, address arbitrumCCIPBnM);

    // Errors
    error RequestTooFrequent();
    error InvalidPairAddress();
    error UnauthorizedRequest();
    error ResponseDecodingFailed();

    /**
     * @notice Constructor
     * @param _subscriptionId Your Functions subscription ID (5056)
     * @param _planStore Address of deployed PlanStore contract
     * @param _ethereumPair Ethereum WETH/CCIP-BnM pair address
     * @param _arbitrumPair Arbitrum WETH/CCIP-BnM pair address
     * @param _ethereumWETH WETH token address on Ethereum Sepolia
     * @param _ethereumCCIPBnM CCIP-BnM token address on Ethereum Sepolia
     * @param _arbitrumWETH WETH token address on Arbitrum Sepolia
     * @param _arbitrumCCIPBnM CCIP-BnM token address on Arbitrum Sepolia
     */
    constructor(
        uint64 _subscriptionId,
        address _planStore,
        address _ethereumPair,
        address _arbitrumPair,
        address _ethereumWETH,
        address _ethereumCCIPBnM,
        address _arbitrumWETH,
        address _arbitrumCCIPBnM
    ) FunctionsClient(0xb83E47C2bC239B3bf370bc41e1459A34b41238D0) ConfirmedOwner(msg.sender) {
        subscriptionId = _subscriptionId;
        planStore = PlanStore(_planStore);
        ethereumPair = _ethereumPair;
        arbitrumPair = _arbitrumPair;
        ethereumWETH = _ethereumWETH;
        ethereumCCIPBnM = _ethereumCCIPBnM;
        arbitrumWETH = _arbitrumWETH;
        arbitrumCCIPBnM = _arbitrumCCIPBnM;
    }

    /**
     * @notice Sends request to Chainlink Functions to analyze arbitrage opportunities
     * @dev Uses improved arbitrage analysis with proper token ordering
     */
    function sendRequest() external returns (bytes32 requestId) {
        // Rate limiting: minimum 2 minutes between calls
        if (block.timestamp < lastRequestTimestamp + 120) {
            revert RequestTooFrequent();
        }
        
        // Validate pair addresses
        if (ethereumPair == address(0) || arbitrumPair == address(0)) {
            revert InvalidPairAddress();
        }

        // Your improved JavaScript source code with proper token ordering
        string memory sourceCode = 
        "const ETHEREUM_SEPOLIA_RPC = 'https://eth-sepolia.g.alchemy.com/v2/xiJw6cj_7U8PXLSncrSON78PWDXP4Dkl';"
        "const ARBITRUM_SEPOLIA_RPC = 'https://arb-sepolia.g.alchemy.com/v2/xiJw6cj_7U8PXLSncrSON78PWDXP4Dkl';"
        "const ETHEREUM_WETH_CCIPBNM_PAIR = args[0];"
        "const ARBITRUM_WETH_CCIPBNM_PAIR = args[1];"
        "const ETHEREUM_WETH = args[2];"
        "const ETHEREUM_CCIPBNM = args[3];"
        "const ARBITRUM_WETH = args[4];"
        "const ARBITRUM_CCIPBNM = args[5];"
        "const ANTHROPIC_API_KEY = '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';"
        "const ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages';"
        "const GET_RESERVES_ABI = '0x0902f1ac';"
        "const TOKEN0_ABI = '0x0dfe1681';"
        "const TOKEN1_ABI = '0xd21220a7';"
        "async function makeRpcCall(rpcUrl, contractAddress, data) {"
        "const response = await Functions.makeHttpRequest({"
        "url: rpcUrl, method: 'POST', headers: {'Content-Type': 'application/json'},"
        "data: {jsonrpc: '2.0', method: 'eth_call', params: [{to: contractAddress, data: data}, 'latest'], id: 1}"
        "});"
        "if (response.error) throw new Error(`RPC call failed: ${response.error}`);"
        "return response.data.result;"
        "}"
        "async function getGasPrice(rpcUrl) {"
        "const response = await Functions.makeHttpRequest({"
        "url: rpcUrl, method: 'POST', headers: {'Content-Type': 'application/json'},"
        "data: {jsonrpc: '2.0', method: 'eth_gasPrice', params: [], id: 1}"
        "});"
        "if (response.error) throw new Error(`Gas price call failed: ${response.error}`);"
        "return BigInt(response.data.result);"
        "}"
        "function decodeReserves(data) {"
        "const hex = data.startsWith('0x') ? data.slice(2) : data;"
        "const reserve0Hex = hex.slice(0, 64);"
        "const reserve1Hex = hex.slice(64, 128);"
        "const timestampHex = hex.slice(128, 192);"
        "return {"
        "reserve0: BigInt('0x' + reserve0Hex),"
        "reserve1: BigInt('0x' + reserve1Hex),"
        "blockTimestampLast: parseInt('0x' + timestampHex, 16)"
        "};"
        "}"
        "function decodeAddress(data) {"
        "const hex = data.startsWith('0x') ? data.slice(2) : data;"
        "return '0x' + hex.slice(24, 64);"
        "}"
        "async function determineTokenOrder(rpcUrl, pairAddress, wethAddress) {"
        "const token0Data = await makeRpcCall(rpcUrl, pairAddress, TOKEN0_ABI);"
        "const token0Address = decodeAddress(token0Data);"
        "return token0Address.toLowerCase() === wethAddress.toLowerCase();"
        "}"
        "function calculatePrice(reserve0, reserve1, token0IsWETH) {"
        "if (token0IsWETH) {"
        "return Number(reserve1) / Number(reserve0);"
        "} else {"
        "return Number(reserve0) / Number(reserve1);"
        "}"
        "}"
        "async function queryAnthropicLLM(prompt) {"
        "console.log('Making Anthropic API call...');"
        "const response = await Functions.makeHttpRequest({"
        "url: ANTHROPIC_API_URL, method: 'POST',"
        "headers: {'Content-Type': 'application/json', 'x-api-key': ANTHROPIC_API_KEY, 'anthropic-version': '2023-06-01'},"
        "data: {model: 'claude-3-5-sonnet-20241022', max_tokens: 1000, messages: [{role: 'user', content: prompt}]}"
        "});"
        "console.log('Anthropic response received:', JSON.stringify(response, null, 2));"
        "if (response.error) throw new Error(`Anthropic API call failed: ${response.error}`);"
        "if (response.data && response.data.content && Array.isArray(response.data.content) && response.data.content.length > 0) {"
        "return response.data.content[0].text;"
        "} else {"
        "throw new Error(`Unexpected response structure: ${JSON.stringify(response)}`);"
        "}"
        "}"
        "async function main() {"
        "try {"
        "console.log('=== STARTING ARBITRAGE ANALYSIS ===');"
        "console.log('Ethereum WETH:', ETHEREUM_WETH);"
        "console.log('Arbitrum WETH:', ARBITRUM_WETH);"
        "console.log('Ethereum CCIP-BnM:', ETHEREUM_CCIPBNM);"
        "console.log('Arbitrum CCIP-BnM:', ARBITRUM_CCIPBNM);"
        "console.log('Fetching token ordering and reserves...');"
        "const [ethReservesData, arbReservesData, ethToken0IsWETH, arbToken0IsWETH] = await Promise.all(["
        "makeRpcCall(ETHEREUM_SEPOLIA_RPC, ETHEREUM_WETH_CCIPBNM_PAIR, GET_RESERVES_ABI),"
        "makeRpcCall(ARBITRUM_SEPOLIA_RPC, ARBITRUM_WETH_CCIPBNM_PAIR, GET_RESERVES_ABI),"
        "determineTokenOrder(ETHEREUM_SEPOLIA_RPC, ETHEREUM_WETH_CCIPBNM_PAIR, ETHEREUM_WETH),"
        "determineTokenOrder(ARBITRUM_SEPOLIA_RPC, ARBITRUM_WETH_CCIPBNM_PAIR, ARBITRUM_WETH)"
        "]);"
        "const ethReserves = decodeReserves(ethReservesData);"
        "const arbReserves = decodeReserves(arbReservesData);"
        "console.log('Token ordering - Ethereum token0 is WETH:', ethToken0IsWETH);"
        "console.log('Token ordering - Arbitrum token0 is WETH:', arbToken0IsWETH);"
        "const ethPrice = calculatePrice(ethReserves.reserve0, ethReserves.reserve1, ethToken0IsWETH);"
        "const arbPrice = calculatePrice(arbReserves.reserve0, arbReserves.reserve1, arbToken0IsWETH);"
        "console.log('=== PRICE ANALYSIS ===');"
        "console.log('Ethereum WETH/CCIP-BnM reserves:', ethReserves.reserve0.toString(), '/', ethReserves.reserve1.toString());"
        "console.log('Arbitrum WETH/CCIP-BnM reserves:', arbReserves.reserve0.toString(), '/', arbReserves.reserve1.toString());"
        "console.log('Ethereum price (CCIP-BnM per WETH):', ethPrice.toFixed(6));"
        "console.log('Arbitrum price (CCIP-BnM per WETH):', arbPrice.toFixed(6));"
        "const edgeBps = arbPrice > ethPrice ? Math.floor(((arbPrice - ethPrice) * 10000) / ethPrice) : Math.floor(((ethPrice - arbPrice) * 10000) / arbPrice);"
        "console.log('Price difference (basis points):', edgeBps);"
        "console.log('======================');"
        "const [ethGasPrice, arbGasPrice] = await Promise.all([getGasPrice(ETHEREUM_SEPOLIA_RPC), getGasPrice(ARBITRUM_SEPOLIA_RPC)]);"
        "const ethGasGwei = Number(ethGasPrice) / 1e9;"
        "const arbGasGwei = Number(arbGasPrice) / 1e9;"
        "const prompt = `You are a cross-chain arbitrage analysis system. Based on the following market data, decide whether to execute an arbitrage trade: MARKET DATA: - Ethereum Sepolia WETH/CCIP-BnM price: ${ethPrice.toFixed(6)} CCIP-BnM per WETH - Arbitrum Sepolia WETH/CCIP-BnM price: ${arbPrice.toFixed(6)} CCIP-BnM per WETH - Price difference: ${edgeBps} basis points - Ethereum gas price: ${ethGasGwei.toFixed(2)} gwei - Arbitrum gas price: ${arbGasGwei.toFixed(2)} gwei ARBITRAGE STRATEGY: - Buy WETH with CCIP-BnM on the cheaper chain - Send CCIP-BnM cross-chain via Chainlink CCIP - Sell CCIP-BnM for WETH on the more expensive chain - Profit = difference in WETH prices minus gas costs DECISION CRITERIA: - Minimum profitable edge: 50 basis points (0.5%) - Maximum gas price: 50 gwei - Suggested trade size: 1-10 WETH based on edge size and liquidity REQUIRED RESPONSE FORMAT (JSON only, no explanation): { \"execute\": true/false, \"amount\": \"amount_in_wei_as_string\", \"minEdgeBps\": minimum_edge_threshold, \"maxGasGwei\": maximum_gas_threshold } If execute is true, provide the exact amount in wei (as string) and thresholds. If execute is false, set amount to \"0\".`;"
        "console.log('Querying Anthropic LLM for arbitrage decision...');"
        "const llmResponse = await queryAnthropicLLM(prompt);"
        "let decision;"
        "try {"
        "let responseText = llmResponse;"
        "if (typeof llmResponse === 'object' && llmResponse.content) {"
        "if (Array.isArray(llmResponse.content) && llmResponse.content.length > 0) {"
        "responseText = llmResponse.content[0].text;"
        "} else if (typeof llmResponse.content === 'string') {"
        "responseText = llmResponse.content;"
        "}"
        "}"
        "console.log('LLM Response:', responseText);"
        "const jsonMatch = responseText.match(/\\{[\\s\\S]*\\}/);"
        "if (!jsonMatch) throw new Error('No JSON found in response');"
        "decision = JSON.parse(jsonMatch[0]);"
        "} catch (parseError) {"
        "console.error('Failed to parse LLM response:', llmResponse);"
        "throw new Error(`LLM response parsing failed: ${parseError.message}`);"
        "}"
        "if (typeof decision.execute !== 'boolean' || typeof decision.amount !== 'string' || typeof decision.minEdgeBps !== 'number' || typeof decision.maxGasGwei !== 'number') {"
        "throw new Error('Invalid decision structure from LLM');"
        "}"
        "console.log(`Decision: execute=${decision.execute}, amount=${decision.amount} wei`);"
        "return Functions.encodeUint256(decision.execute ? 1 : 0) + Functions.encodeUint256(BigInt(decision.amount)) + Functions.encodeUint256(BigInt(decision.minEdgeBps)) + Functions.encodeUint256(BigInt(decision.maxGasGwei)) + Functions.encodeUint256(BigInt(0));"
        "} catch (error) {"
        "console.error('Error in arbitrage analysis:', error.message);"
        "return Functions.encodeUint256(0) + Functions.encodeUint256(BigInt(0)) + Functions.encodeUint256(BigInt(50)) + Functions.encodeUint256(BigInt(50)) + Functions.encodeUint256(BigInt(0));"
        "}"
        "}"
        "return main();";

        // Build Functions request
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(sourceCode);
        
        // Set arguments: [ethereumPair, arbitrumPair, ethereumWETH, ethereumCCIPBnM, arbitrumWETH, arbitrumCCIPBnM]
        string[] memory args = new string[](6);
        args[0] = toHexString(ethereumPair);
        args[1] = toHexString(arbitrumPair);
        args[2] = toHexString(ethereumWETH);
        args[3] = toHexString(ethereumCCIPBnM);
        args[4] = toHexString(arbitrumWETH);
        args[5] = toHexString(arbitrumCCIPBnM);
        req.setArgs(args);

        // Send request to Chainlink Functions
        requestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            DON_ID
        );

        // Track request
        pendingRequests[requestId] = true;
        lastRequestTimestamp = block.timestamp;
        requestCount++;

        emit RequestSent(requestId, block.timestamp);
        return requestId;
    }

    /**
     * @notice Chainlink Functions callback - receives response from network
     * @param requestId The request ID
     * @param response The response data from Functions
     * @param err Error data if the request failed
     */
    function _fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        // Verify this was our request
        if (!pendingRequests[requestId]) {
            revert UnauthorizedRequest();
        }
        
        // Clear pending status
        pendingRequests[requestId] = false;

        // Handle errors
        if (err.length > 0) {
            emit RequestFailed(requestId, string(err));
            return;
        }

        // Handle empty response (no execution recommended)
        if (response.length == 0) {
            emit RequestFulfilled(requestId, false, 0);
            return;
        }

        // Decode response: 5 uint256 values packed together
        try this.decodeResponse(response) returns (
            bool execute,
            uint256 amount,
            uint256 minEdgeBps,
            uint256 maxGasGwei
        ) {
            // If LLM recommends execution, store the plan
            if (execute) {
                // Create arbitrage plan
                PlanStore.ArbitragePlan memory plan = PlanStore.ArbitragePlan({
                    execute: execute,
                    amount: amount,
                    minEdgeBps: minEdgeBps,
                    maxGasGwei: maxGasGwei,
                    timestamp: 0 // Will be set by PlanStore
                });

                // Store plan in PlanStore - this triggers automation!
                planStore.fulfillPlan(abi.encode(plan));
                
                emit RequestFulfilled(requestId, execute, amount);
            } else {
                emit RequestFulfilled(requestId, false, 0);
            }
        } catch {
            emit RequestFailed(requestId, "Failed to decode response");
        }
    }

    /**
     * @notice Decodes Functions response
     * @param response Raw response bytes
     */
    function decodeResponse(bytes memory response) external pure returns (
        bool execute,
        uint256 amount,
        uint256 minEdgeBps,
        uint256 maxGasGwei
    ) {
        // Decode 5 packed uint256 values
        require(response.length >= 160, "Response too short"); // 5 * 32 bytes
        
        uint256 executeInt;
        (executeInt, amount, minEdgeBps, maxGasGwei,) = abi.decode(
            response,
            (uint256, uint256, uint256, uint256, uint256)
        );
        
        execute = executeInt == 1;
    }

    /**
     * @notice Update token addresses (only owner)
     */
    function updateTokenAddresses(
        address _ethereumWETH,
        address _ethereumCCIPBnM,
        address _arbitrumWETH,
        address _arbitrumCCIPBnM
    ) external onlyOwner {
        ethereumWETH = _ethereumWETH;
        ethereumCCIPBnM = _ethereumCCIPBnM;
        arbitrumWETH = _arbitrumWETH;
        arbitrumCCIPBnM = _arbitrumCCIPBnM;
        emit TokenAddressesUpdated(_ethereumWETH, _ethereumCCIPBnM, _arbitrumWETH, _arbitrumCCIPBnM);
    }

    /**
     * @notice Manual trigger for testing
     */
    function manualTrigger() external onlyOwner returns (bytes32) {
        return this.sendRequest();
    }

    /**
     * @notice Store a test arbitrage plan for automation testing
     * @dev This bypasses Functions and directly stores a plan to test automation
     */
    function storeTestPlan() external onlyOwner {
        // Create test arbitrage plan
        PlanStore.ArbitragePlan memory testPlan = PlanStore.ArbitragePlan({
            execute: true,
            amount: 1 ether, // 1 WETH
            minEdgeBps: 50,   // 0.5%
            maxGasGwei: 50,   // 50 gwei
            timestamp: 0      // Will be set by PlanStore
        });
        
        // Store plan in PlanStore - this will trigger automation!
        planStore.fulfillPlan(abi.encode(testPlan));
    }

    /**
     * @notice Converts address to hex string for Functions arguments
     */
    function toHexString(address addr) internal pure returns (string memory) {
        bytes memory data = abi.encodePacked(addr);
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    /**
     * @notice Get configuration info
     */
    function getConfig() external view returns (
        uint64 _subscriptionId,
        address _planStore,
        address _ethereumPair,
        address _arbitrumPair,
        uint256 _lastRequestTimestamp,
        uint256 _requestCount
    ) {
        return (
            subscriptionId,
            address(planStore),
            ethereumPair,
            arbitrumPair,
            lastRequestTimestamp,
            requestCount
        );
    }
} 
