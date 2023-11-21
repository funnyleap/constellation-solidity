// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.19;

// import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
// import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
// import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";

// /**
//  * @title GettingStartedFunctionsConsumer
//  * @notice This is an example contract to show how to make HTTP requests using Chainlink
//  * @dev This contract uses hardcoded values and should not be used in production.
//  */
// contract GettingStartedFunctionsConsumer is FunctionsClient, ConfirmedOwner {
//     using FunctionsRequest for FunctionsRequest.Request;

//     // State variables to store the last request ID, response, and error
//     bytes32 public s_lastRequestId;
//     bytes public s_lastResponse;
//     bytes public s_lastError;

//     // Custom error type
//     error UnexpectedRequestID(bytes32 requestId);

//     // Event to log responses
//     event Response( bytes32 indexed requestId, bytes response, bytes err);

//     struct VehicleData {
//         string value;
//         uint requestTime;
//         uint responseTime;
//     }

//     mapping(bytes32 requestId => VehicleData) public vehicleDataMapping;

//     uint64 private subscriptionId;
//     address router;
//     uint32 gasLimit;
//     bytes32 donID;

//     // JavaScript source code
//     // Fetch vehicle value from the FIPE API.
//     // Documentation: https://github.com/deividfortuna/fipe
//     string source =
//         "const tipoAutomovel = args[0];" //motos
//         "const idMarca = args[1];" //77
//         "const idModelo = args[2];" //5223
//         "const dataModelo = args[3];" //2015-1
//         "const apiResponse = await Functions.makeHttpRequest({"
//             "url: `https://parallelum.com.br/fipe/api/v1/${tipoAutomovel}/marcas/${idMarca}/modelos/${idModelo}/anos/${dataModelo}`"
//         "});"
//         "if (apiResponse.error) {"
//         "throw Error('Request failed');"
//         "}"
//         "const { data } = apiResponse;"
//         "return Functions.encodeString(data.Valor);";


//     constructor(uint64 _subscriptionId, address _routerFunctions, uint32 _gasLimit, bytes32 _donID) FunctionsClient(router) ConfirmedOwner(msg.sender) {
//         subscriptionId = _subscriptionId; //770
//         router = _routerFunctions; // 0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0 - Fuji
//         gasLimit = _gasLimit; // 300000
//         donID = _donID; // 0x66756e2d6176616c616e6368652d66756a692d31000000000000000000000000 - Fuji
//     }


//     function sendRequest(string[] calldata args) external onlyOwner returns (bytes32 requestId) {
//         FunctionsRequest.Request memory req;

//         req.initializeRequestForInlineJavaScript(source);

//         if (args.length > 0) req.setArgs(args);

//         s_lastRequestId = _sendRequest(
//             req.encodeCBOR(),
//             subscriptionId,
//             gasLimit,
//             donID
//         );
        
//         VehicleData memory vehicleInfo = VehicleData ({
//             value: "",
//             requestTime: block.timestamp,
//             responseTime: 0
//         });

//         vehicleDataMapping[s_lastRequestId] = vehicleInfo;

//         return s_lastRequestId;
//     }

//     /**
//      * @notice Callback function for fulfilling a request
//      * @param requestId The ID of the request to fulfill
//      * @param response The HTTP response data
//      * @param err Any errors from the Functions request
//      */
//     function fulfillRequest( bytes32 requestId, bytes memory response, bytes memory err) internal override {

//         if (s_lastRequestId != requestId) {
//             revert UnexpectedRequestID(requestId); // Check if request IDs match
//         }

//         // Update the contract's state variables with the response and any errors
//         s_lastResponse = response;
//         s_lastError = err;

//         vehicleDataMapping[requestId].value = string(response);
//         vehicleDataMapping[requestId].responseTime = block.timestamp;

//         // Emit an event to log the response
//         emit Response(requestId, s_lastResponse, s_lastError);
//     }
// }
