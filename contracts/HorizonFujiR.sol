// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./HorizonFunctions.sol";
import "./HorizonFujiS.sol";

// Custom errors to provide more descriptive revert messages.
error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
error NothingToWithdrawal();
error FailedToWithdrawalEth(address owner, address target, uint256 value);
error DestinationChainNotWhitelisted(uint64 destinationChainSelector);
error SourceChainNotWhitelisted(uint64 sourceChainSelector);
error SenderNotWhitelisted(address sender);

/**
 * @title Horizon CCIP Receiver - FUJI
 * @author Barba
 * @notice This contract is responsable for receive and store the RWA tokens and registers
 */
contract HorizonFujiR is CCIPReceiver,OwnerIsCreator {

    ///@notice Event emitted when a message is received from another chain.
    event MessageReceived( bytes32 indexed messageId, uint64 indexed sourceChainSelector, address sender, string text);
    ///@notice Event emitted when the Rwa value is not enought to cover insurance value needed
    event TheRwaValueIsLessThanTheMinimumNeeded(uint _rwaId, uint _rwaValue);
    ///@notice Evento emitido quando é iniciada a verificação do valor do RWA
    event VerifyingRwaValue(uint _rwaId, string[] args);
    ///@notice Evento emitido quando um RWA é alocado como colateral
    event EnsuranceAdd(address provisoryOwner, uint _rwaId, uint _titleId, uint _drawNumber);
    ///@notice Evento emitido quando o RWA é devolvido ao seu proprietário
    event RWARefunded(uint _titleId, uint _drawNumber, address _rwaOwner, uint _collateralId);
    ///@notice Evento emitido quando o valor do RWA é atualizado pelo Chainlink Automation
    event RwaValueUpdated(bytes32 requestId, string[] args);
    ///@notice Evento emitido quando o Chainlink automation executa sua tarefa periódica
    event UpkeepPerformed( uint value);
    ///@notice Evento emitido quando o valor do RWA não sofre alteração
    event RWAPriceAtMoment(uint _contractId, uint _rwaId, uint _rwaValue);
    ///@notice Evento emitido quando o valor do RWA reduz
    event PriceLowEvent(uint _contractId, uint _rwaId, uint _rwaValue);
    ///@notice Evento emitido quando o valor do RWA reduz de maneira crítica
    event TitleCancelledTheRWAWillBeSold(uint _contractId,  uint _rwaId, uint _rwaValue);

    ///@notice CCIP State Variables to store the last id
    bytes32 private lastReceivedMessageId;
    ///@notice CCIP State Variables to store the received text
    bytes private lastReceivedText;
    
    ///@notice State variable to store the polygon receiver address
    address private horizonR;

    ///@notice State variables to store the Functions params
    uint64 private subscriptionId;
    address router;
    uint32 gasLimit;
    bytes32 donID;

    ///@notice Link token interface instantiation
    LinkTokenInterface linkToken;

    /**
     * @notice Permissios Struct
     */
    struct Permissions {
        uint idTitle;
        uint drawNumber;
        uint contractId;
        address rwaOwner;
        uint ensuranceValueNeeded;
        uint ensureValueNow;
        uint collateralId;
        string[] args;
        bytes32 lastRequestId;
        uint lastRequestTime;
        uint lastResponseTime;
        bool collateralLocked;
        bool isPermission;
    }

    /**
     * @notice Struct to store the RWA's infos
     */
    struct RwaMonitor{
        uint rwaId;
        bytes32 hashPermission;
        string[] args;
        bytes32 lastRequestId;
        bool isActive;
    }

    /// @notice  Array to keep track of RWA's prices
    RwaMonitor[] public rwaMonitors;
    /// @notice  Mapping to keep track of collateral permissions
    mapping(bytes32 => Permissions) public permissionsInfo;
    /// @notice  Mapping to keep track of whitelisted source chains.
    mapping(uint64 => bool) public whitelistedSourceChains;
    /// @notice  Mapping to keep track of whitelisted senders.
    mapping(address => bool) public whitelistedSenders;

    /// @dev CCIP sender instantiation
    HorizonFujiS sender = HorizonFujiS(payable(0x14c9188071620Abcd778A20f5b344c515AB9c0f9));
    /// @dev Functions instantiation
    HorizonFunctions functions = HorizonFunctions(payable(0x317383204E6406B61258cB53D535AE770B7a984F));
    /// @dev RWA Mockup instantiation
    ERC721 rwa = ERC721(payable(0xD7ECF0bbe82717eAd041eeF0B9E777e1A7D577a0));

    constructor(address _linkToken,
                address _routerCCIP) CCIPReceiver(_routerCCIP) {
        linkToken = LinkTokenInterface(_linkToken);
    }

    /**
     * @notice This function add the address receiver to the state variable
     * @param _receiverAddress polygon CCIP receiver
     * @dev This function pourpose is to attend the hackathon in test enviroment
     */
    function addReceiver(address _receiverAddress) public onlyOwner{
        horizonR = _receiverAddress;
    }

    /**
     * @notice this function receive the message from the main contract and process the data.
     * @param any2EvmMessage CCIP ramp message
     */
    function _ccipReceive( Client.Any2EVMMessage memory any2EvmMessage) internal override onlyWhitelistedSourceChain(any2EvmMessage.sourceChainSelector) onlyWhitelistedSenders(abi.decode(any2EvmMessage.sender, (address))) {
        lastReceivedMessageId = any2EvmMessage.messageId;
        lastReceivedText = abi.decode(any2EvmMessage.data, (bytes));

        bytes32 permissionHash;
        uint _ensuranceValueNeeded;
        bool _collateralLocked;

        (permissionHash, _ensuranceValueNeeded, _collateralLocked) = abi.decode(lastReceivedText, (bytes32, uint, bool));

        handlePermission(permissionHash, _ensuranceValueNeeded, _collateralLocked);

        emit MessageReceived( any2EvmMessage.messageId, any2EvmMessage.sourceChainSelector, abi.decode(any2EvmMessage.sender, (address)), abi.decode(any2EvmMessage.data, (string)));
    }

    /**
     * @notice this function is responsable to handle the decoded message received from ccip.
     * @param _permissionHash Is the unique key used to store the RWA infos and create permission
     * @param _ensuranceValueNeeded The minimum value that RWA must have to be allocated
     * @param _collateralLocked The state of collateral. If true, the permission will be created. If False, the Collateral will be refunded.
     * @dev the permissionHash is result of an encoding process of titleId, contractId and drawSelected
     */
    function handlePermission(bytes32 _permissionHash,
                              uint _ensuranceValueNeeded,
                              bool _collateralLocked) internal{

        string[] memory emptyArray = new string[](0);

        Permissions memory permission = Permissions({
            idTitle: 0,
            contractId: 0,
            drawNumber: 0,
            rwaOwner: address(0),
            ensuranceValueNeeded: (_ensuranceValueNeeded * 5),
            ensureValueNow: 0,
            collateralId: 0,
            args: emptyArray,
            lastRequestId: 0,
            lastRequestTime: 0,
            lastResponseTime: 0,
            collateralLocked: _collateralLocked,
            isPermission: true
        });

        if(_collateralLocked == true){
            permissionsInfo[_permissionHash] = permission;
        }else{
            if(_collateralLocked == false){
                sendRwaBackToOwner(_permissionHash);
            }
        }
    }

    /**
     * @notice This functions is responsable to verify the collateral value
     * @param _titleId The ID of the Consórcio Title that the customer purchased a Quota from.
     * @param _contractId The ID of the Consórcio Quota
     * @param _drawNumber The Draw Number where the client where selected
     * @param _rwaId The RWA ID that will be allocated
     * @param args An array of string with the RWA infos
     */
    function verifyCollateralValue(uint256 _titleId, uint _contractId, uint _drawNumber, uint _rwaId, string[] calldata args) public {
        bytes32 permissionHash = keccak256(abi.encodePacked(_titleId, _contractId, _drawNumber));
        bytes32 requestId = functions.sendRequest(args);

        require(permissionsInfo[permissionHash].isPermission == true, "This permission didn't exists!");
        require(msg.sender == rwa.ownerOf(_rwaId), "You must be the owner of the informed RWA!");

        Permissions storage permission = permissionsInfo[permissionHash];

        permission.idTitle = _titleId;
        permission.contractId = _contractId;
        permission.drawNumber = _drawNumber;
        permission.rwaOwner = msg.sender;
        permission.collateralId = _rwaId;
        permission.args = args;
        permission.lastRequestId = requestId;

        emit VerifyingRwaValue(_rwaId, args);
    }

    /**
     * @notice This function is responsable to lock the collateral RWA and send the result to the main contract in Mumbai
     * @param _titleId The ID of the Consórcio Title that the customer purchased a Quota from.
     * @param _contractId The ID of the Consórcio Quota
     * @param _drawNumber The Draw Number where the client where selected
     * @param _rwaId The RWA ID that will be allocated
     */ 
    function addCollateral(uint256 _titleId, uint _contractId, uint _drawNumber, uint _rwaId) public {
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
                args: permission.args,
                lastRequestId: 0,
                isActive: true
            }));
            
            bytes memory collateralAdded = abi.encode(permissionHash, rwa, _rwaId);

            sender.sendMessagePayLINK(12532609583862916517, horizonR, collateralAdded);

            emit EnsuranceAdd(provisoryOwner, _rwaId, _titleId, _drawNumber);
        } else{
            emit TheRwaValueIsLessThanTheMinimumNeeded(_rwaId, vehicleValue);
        }
    }

    /**
     * @notice this function is responsable to refund the Collateral
     * @param _permissionHash the unique key used to create and acess the permissions
     * @dev the permissionHash is result of an encoding process of titleId, contractId and drawSelected
     */
    function sendRwaBackToOwner(bytes32 _permissionHash) internal {
        require(permissionsInfo[_permissionHash].isPermission == true, "This permission didnt exists!");

        Permissions storage permission = permissionsInfo[_permissionHash];

        for(uint i = 0; rwaMonitors[i].hashPermission != _permissionHash; i++){
            if(rwaMonitors[i].hashPermission == _permissionHash){
                rwaMonitors[i].isActive = false;
            }
        }

        rwa.safeTransferFrom(address(this), permission.rwaOwner, permission.collateralId);

        emit RWARefunded(permission.idTitle, permission.drawNumber, permission.rwaOwner, permission.collateralId);
    }
    
    /**
     * @notice This function is responsable to call chainlink functions and monitore the RWA value
     * Triggered by Automation
     */
    function checkCollateralPrice() external {
        for (uint256 i = 0; i < rwaMonitors.length; i++) {

            if(rwaMonitors[i].isActive == true){
                string[] memory args = rwaMonitors[i].args;
                
                bytes32 requestId = functions.sendRequest(args);

                rwaMonitors[i].lastRequestId = requestId;

                emit RwaValueUpdated(requestId, args);
            }
        }
    }

    /**
     * @notice This function is responsable to get the collateral value from the functions contract
     * Triggered by frontend
     */
    function getCollateralPrice() external {
        for (uint256 i = 0; i < rwaMonitors.length; i++) {
            if(rwaMonitors[i].isActive == true){

                bytes32 lastRequest = rwaMonitors[i].lastRequestId;

                (uint vehicleValue, uint responseTime) = functions.returnFunctionsInfo(lastRequest);

                bytes32 permissionHash = rwaMonitors[i].hashPermission;

                Permissions storage permission = permissionsInfo[permissionHash];

                permission.ensureValueNow = vehicleValue;
                permission.lastResponseTime = responseTime;

                uint rwaId = rwaMonitors[i].rwaId;
                uint referenceValue = permission.ensuranceValueNeeded;

                if (vehicleValue >= (referenceValue * 5)) {
                    emit RWAPriceAtMoment(permission.contractId, rwaId, vehicleValue);

                } else if (vehicleValue >= referenceValue * 4) {
                    emit PriceLowEvent(permission.contractId, rwaId, vehicleValue);

                } else if (vehicleValue < referenceValue * 2) {
                    rwaMonitors[i].isActive = false;
                    emit TitleCancelledTheRWAWillBeSold(permission.contractId, rwaId, vehicleValue);
                }
            }
        }
    }

    /// @dev Whitelists a chain for transactions.
    /// @notice This function can only be called by the owner.
    /// @param _sourceChainSelector The selector of the source chain to be whitelisted.
    function addSourceChain( uint64 _sourceChainSelector) external onlyOwner {
        whitelistedSourceChains[_sourceChainSelector] = true;
    }
    /// @dev Denylists a chain for transactions.
    /// @notice This function can only be called by the owner.
    /// @param _sourceChainSelector The selector of the source chain to be denylisted.
    function removelistSourceChain( uint64 _sourceChainSelector) external onlyOwner {
        whitelistedSourceChains[_sourceChainSelector] = false;
    }
    /// @dev Whitelists a sender.
    /// @notice This function can only be called by the owner.
    /// @param _sender The address of the sender.
    function addSender(address _sender) external onlyOwner {
        whitelistedSenders[_sender] = true;
    }
    /// @dev Denylists a sender.
    /// @notice This function can only be called by the owner.
    /// @param _sender The address of the sender.
    function removeSender(address _sender) external onlyOwner {
        whitelistedSenders[_sender] = false;
    }
    /**
     * @notice This function gets the last message received
     * @return messageId 
     * @return text 
     */
    function getLastReceivedMessageDetails() external view returns (bytes32 messageId, bytes memory text) {
        return (lastReceivedMessageId, lastReceivedText);
    }

    receive() external payable {}

    /**
     * @notice Basic chainlink Withdrawal function
     * @param _beneficiary The address to recive the value
     */
    function withdrawal(address _beneficiary) public onlyOwner {
        
        uint256 amount = address(this).balance;

        if (amount == 0) revert NothingToWithdrawal();
        
        (bool sent, ) = _beneficiary.call{value: amount}("");

        if (!sent) revert FailedToWithdrawalEth(msg.sender, _beneficiary, amount);
    }

    /**
     * @notice Basic chainlink Withdrawal function
     * @param _beneficiary The address to recive the value
     */
    function withdrawalToken( address _beneficiary, address _token) public onlyOwner {
        
        uint256 amount = IERC20(_token).balanceOf(address(this));

        if (amount == 0) revert NothingToWithdrawal();

        IERC20(_token).transfer(_beneficiary, amount);
    }

    /// MODIFIERS
    
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
