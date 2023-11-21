// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";

import "./HorizonFujiAssistant.sol";
import "./HorizonFujiS.sol";

// Custom errors to provide more descriptive revert messages.
error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
error NothingToWithdraw();
error FailedToWithdrawEth(address owner, address target, uint256 value);
error DestinationChainNotWhitelisted(uint64 destinationChainSelector);
error SourceChainNotWhitelisted(uint64 sourceChainSelector);
error SenderNotWhitelisted(address sender);
error UnexpectedRequestID(bytes32 requestId);

contract HorizonFujiR is CCIPReceiver, FunctionsClient, ConfirmedOwner {

    using SafeMath for uint256;

    // Event emitted when a message is received from another chain.
    event MessageReceived( bytes32 indexed messageId, uint64 indexed sourceChainSelector, address sender, string text);
    event TheRwaValueIsLessThanTheMinimumNeeded(uint _rwaId, uint _rwaValue);
    event VerifyingRwaValue(uint _rwaId, string[] args);
    event EnsuranceAdd(address provisoryOwner, uint _rwaId, uint _titleId, uint _drawNumber);
    event RWARefunded(uint _titleId, uint _drawNumber, address _rwaOwner, uint _colateralId);
    event RWAPriceAtMoment(uint _contractId, ERC721 _colateralAddresses, int _rwaValue, uint _referenceValue);
    event PriceLowEvent(uint _contractId, ERC721 _colateralAddresses, int _rwaValue, uint _referenceValue);
    event TitleCancelledTheRWAWillBeSold(uint _contractId, RwaMonitor[] rwaMonitors, uint rwaValue);
    event Response( bytes32 indexed requestId, bytes response, bytes err);

    //CCIP State Variables to store the last id, received text
    bytes32 private lastReceivedMessageId;
    bytes private lastReceivedText;
    
    // Functions State variables to store the last request ID, response, and error
    bytes32 public s_lastRequestId;
    
    //State variable to store the polygon receiver address
    address private horizonR;

    //State variables to store the Functions params
    uint64 private subscriptionId;
    address router;
    uint32 gasLimit;
    bytes32 donID;

    //State variables to store the CCIP params
    LinkTokenInterface linkToken;
    
    struct Permissions {
        uint idTitle;
        uint drawNumber;
        uint contractId;
        address rwaOwner;
        uint ensuranceValueNeeded;
        uint ensureValueNow;
        uint colateralId;
        string[] args;
        bytes32 lastRequestId;
        uint lastRequestTime;
        uint lastResponseTime;
        bool colateralLocked;
        bool isPermission;
    }

    struct VehicleData {
        string value;
        uint uintValue;
        uint requestTime;
        uint responseTime;
        bytes lastResponse;
        bytes lastError;
        bool isRequest;
    }

    struct RwaMonitor{
        uint rwaId;
        bytes32 hashPermission;
        bool isActive;
    }

    //Array to keep track of RWA's prices
    RwaMonitor[] rwaMonitors;
    // Mapping to keep track of colateral permissions
    mapping(bytes32 => Permissions) public permissionsInfo;
    //Mapping to store the requests from Functions
    mapping(bytes32 requestId => VehicleData) public vehicleDataMapping;

    // Mapping to keep track of whitelisted source chains.
    mapping(uint64 => bool) public whitelistedSourceChains;
    // Mapping to keep track of whitelisted senders.
    mapping(address => bool) public whitelistedSenders;

    
    // JavaScript source code
    // Fetch vehicle value from the FIPE API.
    // Documentation: https://github.com/deividfortuna/fipe
    string source =
        "const tipoAutomovel = args[0];" //motos
        "const idMarca = args[1];" //77
        "const idModelo = args[2];" //5223
        "const dataModelo = args[3];" //2015-1
        "const apiResponse = await Functions.makeHttpRequest({"
            "url: `https://parallelum.com.br/fipe/api/v1/${tipoAutomovel}/marcas/${idMarca}/modelos/${idModelo}/anos/${dataModelo}`"
        "});"
        "if (apiResponse.error) {"
        "throw Error('Request failed');"
        "}"
        "const { data } = apiResponse;"
        "return Functions.encodeString(data.Valor);";

    HorizonFujiS sender = HorizonFujiS(payable());//FALTA O ENDEREÇO
    HorizonFujiAssistant assistant = HorizonFujiAssistant(payable());//FALTA O ENDEREÇO
    ERC721 rwa = ERC721(payable());//FALTA O ENDEREÇO

    constructor(uint64 _subscriptionId, //770
                address _routerFunctions, // 0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0 - Fuji
                uint32 _gasLimit, // 300000
                bytes32 _donID, // 0x66756e2d6176616c616e6368652d66756a692d31000000000000000000000000 - Fuji
                address _linkToken, // 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846
                address _routerCCIP) CCIPReceiver(_routerCCIP) { //0x554472a2720e5e7d5d3c817529aba05eed5f82d8
        subscriptionId = _subscriptionId;
        router = _routerFunctions;
        gasLimit = _gasLimit;
        donID = _donID;
        LinkTokenInterface linkToken = LinkTokenInterface(_linkToken);
    }

    function addReceiver(address _receiverAddress) public {
        horizonR = _receiverAddress;
    }

    /* handle a received message*/
    function _ccipReceive( Client.Any2EVMMessage memory any2EvmMessage) internal override /*onlyWhitelistedSourceChain(any2EvmMessage.sourceChainSelector) onlyWhitelistedSenders(abi.decode(any2EvmMessage.sender, (address)))*/ {
        lastReceivedMessageId = any2EvmMessage.messageId; // fetch the messageId
        lastReceivedText = abi.decode(any2EvmMessage.data, (bytes)); // abi-decoding of the sent text

        bytes32 permissionHash;
        uint _ensuranceValueNeeded;
        bool _colateralLocked;

        (permissionHash, _ensuranceValue, _colateralLocked) = abi.decode(lastReceivedText, (bytes32, uint, bool));

        handlePermission(permissionHash, _ensuranceValueNeeded, _colateralLocked);

        emit MessageReceived( any2EvmMessage.messageId, any2EvmMessage.sourceChainSelector, abi.decode(any2EvmMessage.sender, (address)), abi.decode(any2EvmMessage.data, (string)));
    }

    function handlePermission(bytes32 _permissionHash,
                              uint _ensuranceValueNeeded,
                              bool _colateralLocked) internal{

        Permissions memory permission = Permissions({
            idTitle: 0,
            contractId: 0,
            drawNumber: 0,
            rwaOwner: address(0),
            ensuranceValueNeeded: (_ensuranceValueNeeded.mul(5)),
            ensureValueNow: 0,
            colateralId: 0,
            requstId: 0,
            lastRequestTime: 0
            lastResponseTime: 0
            colateralLocked: _colateralLocked,
            isPermission: true
        });

        if(_colateralLocked == true){
            permissionsInfo[_permissionHash] = permission;
        }else{
            if(_colateralLocked == false){
                sendRwaBackToOwner(_permissionHash);
            }
        }
    }

    function verifyColateralValue(uint256 _titleId, uint _contractId, uint _drawNumber, uint _rwaId, string[] calldata args) { //["motos",77,5223,"2015-1"]
        bytes32 permissionHash = keccak256(abi.encodePacked(_titleId, _contractId, _drawNumber));

        require(permissionsInfo[permissionHash].isPermission == true, "This permission didn't exists!");
        require(msg.sender == rwa.ownerOf(_rwaId), "You must be the owner of the informed RWA!")

        Permissions storage permission = permissionsInfo[permissionHash];

        permission.idTitle = _titleId;
        permission.contractId = _contractId;
        permission.drawNumber = _drawNumber;
        poermission.rwaOwner = msg.sender;
        permission.colateralId = _rwaId;
        permission.args = args;

        emit VerifyingRwaValue(_rwaId, args);

        sendRequest(args, permissionHash);
    }

    function sendRequest(string[] calldata args, bytes32 permissionHash) external onlyOwner returns (bytes32 requestId) { //["motos",77,5223,"2015-1"]

        FunctionsRequest.Request memory req;

        req.initializeRequestForInlineJavaScript(source);

        if (args.length > 0) req.setArgs(args);

        s_lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, gasLimit, donID);

        Permissions storage permission = permissionsInfo[permissionHash];

        permission.lastRequestId = s_lastRequestId;
        permission.lastRequestTime = block.timestamp;
        
        VehicleData memory vehicleInfo = VehicleData ({
            value: "",
            uintValue: 0,
            requestTime: block.timestamp,
            responseTime: 0,
            lastResponse: 0,
            lastError: 0,
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

        vehicle.uintValue = (valueConverted.div(5));

        // Emit an event to log the response
        emit Response(requestId, s_lastResponse, s_lastError);
    }

    function addCollateral(uint256 _titleId, uint _contractId, uint _drawNumber, uint _rwaId) public {
        bytes32 permissionHash = keccak256(abi.encodePacked(_titleId, _contractId, _drawNumber));

        Permissions storage permission = permissionsInfo[permissionHash];

        require(permission.isPermission == true, "This permission didn't exists!");

        VehicleData storage vehicle = vehicleDataMapping[permission.lastRequestId];

        If(vehicle.uintValue >= permission.ensuranceValueNeeded){
            
            permission.ensureValueNow = valueConverted;
            permission.lastResponseTime = block.timestamp;

            uint colateralPrice = valueConverted;
            uint targetPrice = permission.ensuranceValueNeeded;

            require(colateralPrice >= targetPrice, "The ensurance must have at least 10 times the value of the value needed!");
            
            rwa.transferFrom(msg.sender, address(this), _rwaId);

            address provisoryOwner = rwa.ownerOf(_rwaId);

            bytes memory colateralAdded = abi.encode(permissionHash, rwa, _rwaId);

            rwaMonitors.push(RwaMonitor({
                rwaId: _rwaId,
                hashPermission: permissionHash,
                isActive: true
            }));

            sender.sendMessagePayLINK(12532609583862916517, polygonReceiver, colateralAdded); //Destination chainId - 12532609583862916517

            emit EnsuranceAdd(provisoryOwner, _rwaId, _titleId, _drawNumber);
        } else{
            emit TheRwaValueIsLessThanTheMinimumNeeded(vehicle.rwaId, valueConverted);
        }
    }

    function sendRwaBackToOwner(bytes32 _permissionHash) internal{
        require(permissionsInfo[_permissionHash].isPermission == true, "This permission didnt exists!");

        Permissions storage permission = permissionsInfo[_permissionHash];

        for(i = 0; rwaMonitors[i].hashPermission != _permissionHash; i++){
            if(rwaMonitors[i].hashPermission == _permissionHash){
                rwaMonitors[i].isActive = false;
            }
        }

        rwa.safeTransferFrom(address(this), permission.rwaOwner, permission.colateralId);

        emit RWARefunded(permission.idTitle, permission.drawNumber, permission.rwaOwner, permission.colateralId);
    }
        
    function checkColateralPrice() internal { //Triggered by Automation
        for (uint256 i = 0; i < rwaMonitors.length; i++) {

            if(rwaMonitors[i].isActive == true){
                Permissions storage permission = permissionsInfo[rwaMonitors[i].hashPermission];
                
                sendRequest(permission.args, rwaMonitors[i].hashPermission);

                VehicleData storage vehicle = vehicleDataMapping[permission.lastRequestId];

                permission.ensureValueNow = vehicle.uintValue;
                permission.lastResponseTime = vehicle.responseTime;

                uint rwaValue = vehicle.uintValue;
                uint referenceValue = permission.ensuranceValue;

                if (rwaValue >= (referenceValue.mul(5))) {
                    emit RWAPriceAtMoment(permission.contractId, rwaMonitors[i], rwaValue);

                } else if (rwaValue >= referenceValue.mul(4)) {
                    emit PriceLowEvent(permission.contractId, rwaMonitors[i], rwaValue); //ALERT

                } else if (rwaValue < referenceValue.mul(2)) {
                    rwaMonitors[i].isActive = false;
                    emit TitleCancelledTheRWAWillBeSold(permission.contractId, rwaMonitors[i], rwaValue);
                }
            }
        }
    }

    /// @dev Whitelists a chain for transactions.
    /// @notice This function can only be called by the owner.
    /// @param _sourceChainSelector The selector of the source chain to be whitelisted.
    function addSourceChain( uint64 _sourceChainSelector) external /*onlyOwner*/ {
        whitelistedSourceChains[_sourceChainSelector] = true;
    }
    /// @dev Denylists a chain for transactions.
    /// @notice This function can only be called by the owner.
    /// @param _sourceChainSelector The selector of the source chain to be denylisted.
    function removelistSourceChain( uint64 _sourceChainSelector) external /*onlyOwner*/ {
        whitelistedSourceChains[_sourceChainSelector] = false;
    }
    /// @dev Whitelists a sender.
    /// @notice This function can only be called by the owner.
    /// @param _sender The address of the sender.
    function addSender(address _sender) external /*onlyOwner*/ {
        whitelistedSenders[_sender] = true;
    }
    /// @dev Denylists a sender.
    /// @notice This function can only be called by the owner.
    /// @param _sender The address of the sender.
    function removeSender(address _sender) external /*onlyOwner*/ {
        whitelistedSenders[_sender] = false;
    }

    function getLastReceivedMessageDetails() external view returns (bytes32 messageId, bytes memory text) {
        return (lastReceivedMessageId, lastReceivedText);
    }

    /*Withdraw - Receive*/
    receive() external payable {}

    function withdraw(address _beneficiary) public /*onlyOwner*/ {
        // Retrieve the balance of this contract
        uint256 amount = address(this).balance;

        // Revert if there is nothing to withdraw
        if (amount == 0) revert NothingToWithdraw();

        // Attempt to send the funds, capturing the success status and discarding any return data
        (bool sent, ) = _beneficiary.call{value: amount}("");

        // Revert if the send failed, with information about the attempted transfer
        if (!sent) revert FailedToWithdrawEth(msg.sender, _beneficiary, amount);
    }

    function withdrawToken( address _beneficiary, address _token) public /*onlyOwner*/ {
        // Retrieve the balance of this contract
        uint256 amount = IERC20(_token).balanceOf(address(this));

        // Revert if there is nothing to withdraw
        if (amount == 0) revert NothingToWithdraw();

        IERC20(_token).transfer(_beneficiary, amount);
    }

    /*MODIFIERS    */
    modifier onlyWhitelistedSourceChain(uint64 _sourceChainSelector) {
        if (!whitelistedSourceChains[_sourceChainSelector])
            revert SourceChainNotWhitelisted(_sourceChainSelector);
        _;
    }

    modifier onlyWhitelistedSenders(address _sender) {
        if (!whitelistedSenders[_sender]) revert SenderNotWhitelisted(_sender);
        _;
    }
}
