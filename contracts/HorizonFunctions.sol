// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import "./HorizonFujiAssistant.sol";

contract HorizonFunctions is FunctionsClient{
    using FunctionsRequest for FunctionsRequest.Request;

    // State variables to store the last request ID, response, and error
    bytes32 public s_lastRequestId;

    // Custom error type
    error UnexpectedRequestID(bytes32 requestId);

    // Event to log responses
    event Response( bytes32 indexed requestId, bytes response, bytes err);

    struct VehicleData {
        string value;
        uint uintValue;
        uint requestTime;
        uint responseTime;
        bytes lastResponse;
        bytes lastError;
        bool isRequest;
    }

    mapping(bytes32 requestId => VehicleData) public vehicleDataMapping;

    uint64 private subscriptionId;
    address router;
    uint32 gasLimit;
    bytes32 donID;

    HorizonFujiAssistant assistant = HorizonFujiAssistant(payable(0xF5A428c3E5dD31d6474F58Bb64F779216c11a11C));//FALTA O ENDEREÇO

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

    constructor(uint64 _subscriptionId, //1212
                address _routerFunctions, // 0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0 - Fuji
                uint32 _gasLimit, // 300000
                bytes32 _donID // 0x66756e2d6176616c616e6368652d66756a692d31000000000000000000000000 - Fuji
                ) FunctionsClient(_routerFunctions) {
        subscriptionId = _subscriptionId; 
        router = _routerFunctions;
        gasLimit = _gasLimit;
        donID = _donID;
    }

    function sendRequest(string[] calldata args) external returns (bytes32 requestId) { //["motos",77,5223,"2015-1"]

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

    function fulfillRequest( bytes32 requestId, bytes memory response, bytes memory err) internal override {
        VehicleData storage vehicle = vehicleDataMapping[requestId];

        if (vehicle.isRequest == false) {
            revert UnexpectedRequestID(requestId); // Check if request IDs match
        }

        // Update the vehicle mapping with the response and any errors
        vehicle.lastResponse = response;
        vehicle.lastError = err;
        vehicle.value = string(response);
        vehicle.responseTime = block.timestamp;

        uint valueConverted = assistant.stringToUint(vehicle.value); //I need convert into USdolars

        vehicle.uintValue = ((valueConverted / 5) * 10 ** 16);

        // Emit an event to log the response
        emit Response(requestId, response, err);
    }

    function returnFunctionsInfo(bytes32 requestId) external view returns(uint, uint){
        VehicleData storage vehicle = vehicleDataMapping[requestId];
        
        uint vehicleValue = vehicle.uintValue;
        uint responseTime = vehicle.responseTime;

        return (vehicleValue, responseTime);
    }
}
