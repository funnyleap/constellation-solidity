// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import "./HorizonFujiAssistant.sol";

/**
 * @title Horizon Functions
 * @author Barba
 * @notice This contract fetch Web2 Data from the FIPE API using Chainlink Functions
 */
contract HorizonFunctions is FunctionsClient, OwnerIsCreator {
    using FunctionsRequest for FunctionsRequest.Request;

    // State variables to store the last request ID, response, and error
    bytes32 public s_lastRequestId;

    // Custom error type
    error UnexpectedRequestID(bytes32 requestId);

    // Event to log responses
    event Response( bytes32 indexed requestId, uint indexed value, bytes err);

    
    /// @notice Struct to store the RWA info
    struct VehicleData {
        string value;
        uint uintValue;
        uint requestTime;
        uint responseTime;
        bytes lastResponse;
        bytes lastError;
        bool isRequest;
    }
    /// @notice mapping to store the VehicleData struct
    mapping(bytes32 requestId => VehicleData) public vehicleDataMapping;

    uint64 private subscriptionId;
    address router;
    uint32 gasLimit;
    bytes32 donID;

    /// @notice HorizonFujiAssistant instantiation
    HorizonFujiAssistant assistant = HorizonFujiAssistant(payable(0xF5A428c3E5dD31d6474F58Bb64F779216c11a11C));

    // JavaScript source code
    // Fetch vehicle value from the FIPE API.
    // Documentation: https://github.com/deividfortuna/fipe
    string source =
        "const tipoAutomovel = args[0];"
        "const idMarca = args[1];"
        "const idModelo = args[2];"
        "const dataModelo = args[3];"
        "const apiResponse = await Functions.makeHttpRequest({"
        "url: `https://parallelum.com.br/fipe/api/v1/${tipoAutomovel}/marcas/${idMarca}/modelos/${idModelo}/anos/${dataModelo}`,"
        "});"
        "if (apiResponse.error) {"
        "throw Error('Request failed');"
        "}"
        "const { data } = apiResponse;"
        "return Functions.encodeString(data.Valor);";

    constructor(uint64 _subscriptionId,
                address _routerFunctions,
                uint32 _gasLimit,
                bytes32 _donID
                ) FunctionsClient(_routerFunctions) {
        subscriptionId = _subscriptionId; 
        router = _routerFunctions;
        gasLimit = _gasLimit;
        donID = _donID;
    }

    /**
     * @notice this function is responsable to fetch the Vehicle data from the FIPE API
     * @param args string array with all the needed arguments
     */
    function sendRequest(string[] calldata args) external  onlyOwner returns(bytes32 requestId) {

        FunctionsRequest.Request memory req;

        req.initializeRequestForInlineJavaScript(source);

        if (args.length > 0) req.setArgs(args);

        s_lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, gasLimit, donID);
        
        VehicleData memory vehicleInfo = VehicleData ({
            value: "",
            uintValue: 0,
            requestTime: block.timestamp,
            responseTime: 0,
            lastResponse: "",
            lastError: "",
            isRequest: true
        });

        vehicleDataMapping[s_lastRequestId] = vehicleInfo;

        return s_lastRequestId;
    }
    /**
     * @notice This is a callback function that receive the encrypted data
     * @param requestId The id generated when the request is send
     * @param response The encrypted data
     * @param err The error received, if it occurs
     * @dev If wil didn't receive the response, you will have and error
     */
    function fulfillRequest( bytes32 requestId, bytes memory response, bytes memory err) internal override {
        VehicleData storage vehicle = vehicleDataMapping[requestId];

        if (vehicle.isRequest == false) {
            revert UnexpectedRequestID(requestId);
        }

        vehicle.lastResponse = response;
        vehicle.lastError = err;
        vehicle.value = string(response);
        vehicle.responseTime = block.timestamp;

        uint valueConverted = assistant.stringToUint(vehicle.value);

        uint value = ((valueConverted / 5) * 10 ** 16);

        vehicle.uintValue = value;

        emit Response(requestId, value, err);
    }

    /**
     * @notice This function get the data and transmit to Horizon Receiver Fuji
     * @param requestId The id generated when the request is send
     * @return vehicle value
     * @return responseTime blocktimeStamp
     */
    function returnFunctionsInfo(bytes32 requestId) external view  onlyOwner returns(uint, uint){
        VehicleData storage vehicle = vehicleDataMapping[requestId];
        
        uint vehicleValue = vehicle.uintValue;
        uint responseTime = vehicle.responseTime;

        return (vehicleValue, responseTime);
    }
}
