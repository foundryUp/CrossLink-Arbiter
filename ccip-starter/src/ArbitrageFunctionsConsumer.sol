// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {FunctionsClient} from "chainlink-evm/contracts/src/v0.8/functions/v1_3_0/FunctionsClient.sol";
import {ConfirmedOwner} from "chainlink-evm/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "chainlink-evm/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {PlanStore}       from "./PlanStore.sol";

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/resources/link-token-contracts/
 */

/**
 * @title GettingStartedFunctionsConsumer
 * @notice This is an example contract to show how to make HTTP requests using Chainlink
 * @dev This contract uses hardcoded values and should not be used in production.
 */
contract ArbitrageFunctionsConsumer is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;
    PlanStore public immutable planStore;

    // State variables to store the last request ID, response, and error
    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;

    // Custom error type
    error UnexpectedRequestID(bytes32 requestId);

    // Event to log responses
    event Response(
        bytes32 indexed requestId,
        string character,
        bytes response,
        bytes err
    );
    event PlanStored(bool execute, uint256 amount, uint256 minEdgeBps, uint256 maxGasGwei);

    // Router address - Hardcoded for Sepolia
    // Check to get the router address for your supported network https://docs.chain.link/chainlink-functions/supported-networks
    address router = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;

    // JavaScript source code
    // Fetch arbitrage analysis from the deployed API
    string source =
        "const characterId = args[0];"
        "const apiResponse = await Functions.makeHttpRequest({"
        "url: 'https://chainlink-hackathon.onrender.com/api/analyze?ethPair=0xd7471664f91C43c5c3ed2B06734b4a392D94Fe16&arbPair=0xAc6D3a904c37c4B75F1823d1B0238d6d48D8bfB3'"
        "});"
        "if (apiResponse.error) {"
        "throw Error('Request failed');"
        "}"
        "const { data } = apiResponse;"
        "return Functions.encodeString(data.csv);";

    //Callback gas limit
    uint32 gasLimit = 300000;

    // donID - Hardcoded for Sepolia
    // Check to get the donID for your supported network https://docs.chain.link/chainlink-functions/supported-networks
    bytes32 donID =
        0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;

    // State variable to store the returned character information
    string public character;

    /**
     * @notice Initializes the contract with the Chainlink router address and sets the contract owner
     */
    constructor(
        address _planStore
    ) FunctionsClient(router) ConfirmedOwner(msg.sender) {
        planStore = PlanStore(_planStore);
    }

    /**
     * @notice Sends an HTTP request for character information
     * @return requestId The ID of the request
     */
    function sendRequest(
        // uint64 subscriptionId
        // string[] calldata args
    ) external returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source); // Initialize the request with JS code
        // if (args.length > 0) req.setArgs(args); // Set the arguments for the request

        // Send the request and store the request ID
        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            5125,
            gasLimit,
            donID
        );

        return s_lastRequestId;
    }

    /**
     * @notice Callback function for fulfilling a request
     * @param requestId The ID of the request to fulfill
     * @param response The HTTP response data
     * @param err Any errors from the Functions request
     */
    function _fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId); // Check if request IDs match
        }
        // Update the contract's state variables with the response and any errors
        s_lastResponse = response;
        character = string(response);
        s_lastError = err;

        // Emit an event to log the response
        emit Response(requestId, character, s_lastResponse, s_lastError);

        // If we have a successful response, automatically parse and store the plan
        if (err.length == 0 && response.length > 0) {
            try this.storeParsedPlan() {
                // Plan stored successfully
            } catch {
                // Plan storage failed - could emit an error event here
            }
        }
    }
    function splitAndParse()
        public
        view
        returns (
            bool    flag,
            uint256 amount,
            uint256 minEdgeBps,
            uint256 maxGasGwei
        )
    {
        string memory csv=string(character);
        // 1) split into exactly 4 parts
        string[4] memory parts = _split4(csv);

        // 2) parse each part
        flag        = _parseBool(parts[0]);
        amount      = _toUint(parts[1]);
        minEdgeBps  = _toUint(parts[2]);
        maxGasGwei  = _toUint(parts[3]);
    }

    function storeParsedPlan() public  {
        // Using mocksplitAndParse() during testing
        (bool flag, uint256 amount, uint256 minEdgeBps, uint256 maxGasGwei) = splitAndParse();

        PlanStore.ArbitragePlan memory plan = PlanStore.ArbitragePlan({
            execute   : flag,
            amount    : amount,
            minEdgeBps: minEdgeBps,
            maxGasGwei: maxGasGwei,
            timestamp : block.timestamp
        });

        bytes memory encoded = abi.encode(plan);
        planStore.fulfillPlan(encoded);

        emit PlanStored(flag, amount, minEdgeBps, maxGasGwei);
    }

    /// @dev Splits a comma-separated string into 4 substrings
    function _split4(string memory str)
        internal
        pure
        returns (string[4] memory out)
    {
        bytes memory b = bytes(str);
        uint256 start;
        uint256 part;
        for (uint256 i = 0; i <= b.length; i++) {
            if (i == b.length || b[i] == ",") {
                // slice [start..i)
                bytes memory slice = new bytes(i - start);
                for (uint256 j = start; j < i; j++) {
                    slice[j - start] = b[j];
                }
                require(part < 4, "Too many fields");
                out[part++] = string(slice);
                start = i + 1;
            }
        }
        require(part == 4, "Wrong field count");
    }

    /// @dev Convert decimal string to uint256
    function _toUint(string memory s) internal pure returns (uint256 result) {
        bytes memory b = bytes(s);
        for (uint256 i = 0; i < b.length; i++) {
            uint8 c = uint8(b[i]);
            require(c >= 48 && c <= 57, "Invalid digit");
            result = result * 10 + (c - 48);
        }
    }

    /// @dev Parse "true" or "false" into bool
    function _parseBool(string memory s) internal pure returns (bool) {
        bytes memory b = bytes(s);
        if (b.length == 4 &&
            b[0] == "t" && b[1] == "r" &&
            b[2] == "u" && b[3] == "e"
        ) {
            return true;
        }
        if (b.length == 5 &&
            b[0] == "f" && b[1] == "a" &&
            b[2] == "l" && b[3] == "s" &&
            b[4] == "e"
        ) {
            return false;
        }
        revert("Invalid bool");
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
}
