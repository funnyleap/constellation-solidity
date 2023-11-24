// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./HorizonFunctions.sol";
import "./HorizonFujiS.sol";

// Custom errors to provide more descriptive revert messages.
error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
error NothingToWithdraw();
error FailedToWithdrawEth(address owner, address target, uint256 value);
error DestinationChainNotWhitelisted(uint64 destinationChainSelector);
error SourceChainNotWhitelisted(uint64 sourceChainSelector);
error SenderNotWhitelisted(address sender);

contract HorizonFujiR is CCIPReceiver {

    // Event emitted when a message is received from another chain.
    event MessageReceived( bytes32 indexed messageId, uint64 indexed sourceChainSelector, address sender, string text);
    event TheRwaValueIsLessThanTheMinimumNeeded(uint _rwaId, uint _rwaValue);
    event VerifyingRwaValue(uint _rwaId, string[] args);
    event EnsuranceAdd(address provisoryOwner, uint _rwaId, uint _titleId, uint _drawNumber);
    event RWARefunded(uint _titleId, uint _drawNumber, address _rwaOwner, uint _colateralId);
    event RWAPriceAtMoment(uint _contractId, uint _rwaValue, uint _referenceValue);
    event PriceLowEvent(uint _contractId, uint _rwaValue, uint _referenceValue);
    event TitleCancelledTheRWAWillBeSold(uint _contractId,  uint _rwaValue, uint rwaValue);

    //CCIP State Variables to store the last id, received text
    bytes32 private lastReceivedMessageId;
    bytes private lastReceivedText;
    
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

    struct RwaMonitor{
        uint rwaId;
        bytes32 hashPermission;
        bool isActive;
    }

    //Array to keep track of RWA's prices
    RwaMonitor[] rwaMonitors;
    // Mapping to keep track of colateral permissions
    mapping(bytes32 => Permissions) public permissionsInfo;

    // Mapping to keep track of whitelisted source chains.
    mapping(uint64 => bool) public whitelistedSourceChains;
    // Mapping to keep track of whitelisted senders.
    mapping(address => bool) public whitelistedSenders;

    HorizonFujiS sender = HorizonFujiS(payable(0x14c9188071620Abcd778A20f5b344c515AB9c0f9));
    HorizonFunctions functions = HorizonFunctions(payable(0x317383204E6406B61258cB53D535AE770B7a984F));
    ERC721 rwa = ERC721(payable(0xD7ECF0bbe82717eAd041eeF0B9E777e1A7D577a0));

    constructor(address _linkToken, // 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846
                address _routerCCIP) CCIPReceiver(_routerCCIP) { //0x554472a2720e5e7d5d3c817529aba05eed5f82d8
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

        (permissionHash, _ensuranceValueNeeded, _colateralLocked) = abi.decode(lastReceivedText, (bytes32, uint, bool));

        handlePermission(permissionHash, _ensuranceValueNeeded, _colateralLocked);

        emit MessageReceived( any2EvmMessage.messageId, any2EvmMessage.sourceChainSelector, abi.decode(any2EvmMessage.sender, (address)), abi.decode(any2EvmMessage.data, (string)));
    }

    function handlePermission(bytes32 _permissionHash,
                              uint _ensuranceValueNeeded,
                              bool _colateralLocked) internal{

        string[] memory emptyArray = new string[](0);

        Permissions memory permission = Permissions({
            idTitle: 0,
            contractId: 0,
            drawNumber: 0,
            rwaOwner: address(0),
            ensuranceValueNeeded: (_ensuranceValueNeeded * 5),
            ensureValueNow: 0,
            colateralId: 0,
            args: emptyArray,
            lastRequestId: 0,
            lastRequestTime: 0,
            lastResponseTime: 0,
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

    function verifyColateralValue(uint256 _titleId, uint _contractId, uint _drawNumber, uint _rwaId, string[] calldata args) public { //["motos","77","5223","2015-1"]
        bytes32 permissionHash = keccak256(abi.encodePacked(_titleId, _contractId, _drawNumber));
        bytes32 requestId = functions.sendRequest(args);

        require(permissionsInfo[permissionHash].isPermission == true, "This permission didn't exists!");
        require(msg.sender == rwa.ownerOf(_rwaId), "You must be the owner of the informed RWA!");

        Permissions storage permission = permissionsInfo[permissionHash];

        permission.idTitle = _titleId;
        permission.contractId = _contractId;
        permission.drawNumber = _drawNumber;
        permission.rwaOwner = msg.sender;
        permission.colateralId = _rwaId;
        permission.args = args;
        permission.lastRequestId = requestId;

        emit VerifyingRwaValue(_rwaId, args);
    }

    function addCollateral(uint256 _titleId, uint _contractId, uint _drawNumber, uint _rwaId) public {//Não pode add sem ter o valor verificado antes
        bytes32 permissionHash = keccak256(abi.encodePacked(_titleId, _contractId, _drawNumber));

        Permissions storage permission = permissionsInfo[permissionHash];

        bytes32 requestId = permission.lastRequestId;

        require(permission.isPermission == true, "This permission didn't exists!");

        (uint vehicleValue, uint responseTime) = functions.returnFunctionsInfo(requestId);

        require(responseTime > 0, "You must wait the response to be received!");
        require(vehicleValue > permission.ensuranceValueNeeded,"The value of the RWA needs to be greater than the ensuranceValueNeeded!");

        if(vehicleValue > permission.ensuranceValueNeeded){
            
            permission.ensureValueNow = vehicleValue;
            permission.lastResponseTime = responseTime;

            uint targetPrice = permission.ensuranceValueNeeded;

            require(vehicleValue >= targetPrice, "The ensurance must have at least 5 times the value of the value needed!");
            
            rwa.transferFrom(msg.sender, address(this), _rwaId);

            address provisoryOwner = rwa.ownerOf(_rwaId);

            rwaMonitors.push(RwaMonitor({
                rwaId: _rwaId,
                hashPermission: permissionHash,
                isActive: true
            }));
            
            bytes memory colateralAdded = abi.encode(permissionHash, rwa, _rwaId);

            sender.sendMessagePayLINK(12532609583862916517, horizonR, colateralAdded); //Destination chainId - 12532609583862916517

            emit EnsuranceAdd(provisoryOwner, _rwaId, _titleId, _drawNumber);
        } else{
            emit TheRwaValueIsLessThanTheMinimumNeeded(_rwaId, vehicleValue);
        }
    }

    function sendRwaBackToOwner(bytes32 _permissionHash) internal{
        require(permissionsInfo[_permissionHash].isPermission == true, "This permission didnt exists!");

        Permissions storage permission = permissionsInfo[_permissionHash];

        for(uint i = 0; rwaMonitors[i].hashPermission != _permissionHash; i++){
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
                
                bytes32 requestId = functions.sendRequest(permission.args);

                (uint vehicleValue, uint responseTime) = functions.returnFunctionsInfo(requestId);

                permission.ensureValueNow = vehicleValue;
                permission.lastResponseTime = responseTime;

                uint id = rwaMonitors[i].rwaId;
                uint rwaValue = vehicleValue;
                uint referenceValue = permission.ensuranceValueNeeded;

                if (rwaValue >= (referenceValue * 5)) {
                    emit RWAPriceAtMoment(permission.contractId, id, rwaValue);

                } else if (rwaValue >= referenceValue * 4) {
                    emit PriceLowEvent(permission.contractId, id, rwaValue); //ALERT

                } else if (rwaValue < referenceValue * 2) {
                    rwaMonitors[i].isActive = false;
                    emit TitleCancelledTheRWAWillBeSold(permission.contractId, id, rwaValue);
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
