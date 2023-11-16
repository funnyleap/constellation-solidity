// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./HorizonFujiS.sol";

// Custom errors to provide more descriptive revert messages.
error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
error NothingToWithdraw();
error FailedToWithdrawEth(address owner, address target, uint256 value);
error DestinationChainNotWhitelisted(uint64 destinationChainSelector);
error SourceChainNotWhitelisted(uint64 sourceChainSelector);
error SenderNotWhitelisted(address sender);

contract HorizonFujiR is CCIPReceiver, Ownable {

    using SafeMath for uint256;

    bytes32 private lastReceivedMessageId;
    bytes private lastReceivedText;
    address private horizonR;
    
    struct Permissions {
        uint idTitle;
        uint drawNumber;
        uint contractId;
        address rwaOwner;
        uint ensuranceValue;
        ERC721 colateralAddress;
        uint colateralId;
        bool colateralLocked;
        bool isPermission;
    }

    //Array to keep track of RWA's prices
    Permissions[] colateralAddresses;

    // Mapping to keep track of whitelisted source chains.
    mapping(uint64 => bool) public whitelistedSourceChains;
    // Mapping to keep track of whitelisted senders.
    mapping(address => bool) public whitelistedSenders;
    // Mapping to keep track of colateral permissions
    mapping(bytes32 => Permissions) public permissionsInfo;

    
    // Event emitted when a message is received from another chain.
    event MessageReceived( bytes32 indexed messageId, uint64 indexed sourceChainSelector, address sender, string text);
    event EnsuranceAdd(address provisoryOwner, uint _rwaId, uint _titleId, uint _drawNumber);
    event RWARefunded(uint _titleId, uint _drawNumber, address _rwaOwner, uint _colateralId);
    event RWAPriceAtMoment(uint _contractId, ERC721 _colateralAddresses, int _rwaValue, uint _referenceValue);
    event PriceLowEvent(uint _contractId, ERC721 _colateralAddresses, int _rwaValue, uint _referenceValue);

    LinkTokenInterface linkToken = LinkTokenInterface(0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846);//0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846
    HorizonFujiS sender = HorizonFujiS(payable());//FALTA O ENDEREÇO
    ERC721 rwa;

    constructor(address _router) CCIPReceiver(_router) { //0x554472a2720e5e7d5d3c817529aba05eed5f82d8
    }

    function addReceiver(address _receiverAddress) public {
        horizonR = _receiverAddress;
    }

    function handlePermission(bytes32 _permissionHash,
                              uint _ensuranceValue,
                              bool _colateralLocked) internal{

        Permissions memory permission = Permissions({
            idTitle: 0,
            contractId: 0,
            drawNumber: 0,
            rwaOwner: address(0),
            ensuranceValue: _ensuranceValue,
            colateralAddress: ERC721(address(0)),
            colateralId: 0,
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

    function addCollateral(uint256 _titleId, uint _contractId, uint _drawNumber, uint _rwaId, ERC721 _rwaAddress) public {
        bytes32 permissionHash = keccak256(abi.encodePacked(_titleId, _contractId, _drawNumber));

        require(permissionsInfo[permissionHash].isPermission == true, "This permission didn't exists!");

        Permissions storage permission = permissionsInfo[permissionHash];

        permission.idTitle = _titleId;
        permission.contractId = _contractId;
        permission.drawNumber = _drawNumber;
        permission.rwaOwner = msg.sender;
        permission.colateralId = _rwaId;
        permission.colateralAddress = _colectionAddress;

        colateralAddresses.push(permission);

        uint colateralPrice = 10 * 10**18; //Testing pourpose
        uint targetPrice = permission.ensuranceValue;

        require(uint(colateralPrice) >= targetPrice.mul(10), "The ensurance must have at least 10 times the value of the value needed!");
        
        rwa = _colectionAddress;
        rwa.transferFrom(msg.sender, address(this), _rwaId);

        address provisoryOwner = rwa.ownerOf(_rwaId);

        bytes memory colateralAdded = abi.encode(permissionHash, _colectionAddress, _rwaId);

        sender.sendMessagePayLINK(12532609583862916517, polygonReceiver, colateralAdded); //Destination chainId - 12532609583862916517

        emit EnsuranceAdd(provisoryOwner, _rwaId, _titleId, _drawNumber);
    }

    function sendRwaBackToOwner(bytes32 _permissionHash) internal{
        require(permissionsInfo[_permissionHash].isPermission == true, "This permission didnt exists!");

        Permissions storage permission = permissionsInfo[_permissionHash];

        rwa = permission.colateralAddress;

        rwa.safeTransferFrom(address(this), permission.rwaOwner, permission.colateralId);

        emit RWARefunded(permission.idTitle, permission.drawNumber, permission.rwaOwner, permission.colateralId);
    }

    //Tem de reformular com o Functions
    function checkColateralPrice(bytes32 _permissionHash) internal {
        for (uint256 i = 0; i < colateralAddresses.length; i++) {
            // Obter o valor atual do RWA
            int256 rwaValue = 100 * 10**18;
            
            Permissions storage permission = permissionsInfo[_permissionHash];
            
            // Valor de referência
            uint256 referenceValue = permission.ensuranceValue;

            if (uint(rwaValue) >= referenceValue.mul(10)) {
                emit RWAPriceAtMoment(permission.contractId, colateralAddresses[i].colateralAddress, rwaValue, referenceValue);
            } else if (uint(rwaValue) >= referenceValue.mul(6)) {
                // O EVENTO ABAIXO IRÁ 'ALERTAR' O FRONTEND QUE, POR SUA VEZ, IRÁ COMUNICAR O DONO DO RWA QUE ELE PRECISA TOMAR PROVIDENCIA.
                emit PriceLowEvent(permission.contractId, colateralAddresses[i].colateralAddress, rwaValue, referenceValue);
            } else if (uint(rwaValue) < referenceValue.mul(3)) {
                //address rwaAddress = colateralAddresses[i]; PRECISO DESCOBRIR SE SERÁ POSSÍVEL MANTER O RWA NA CARTEIRA DO DONO OU PRECISAREI TRANSFERIR PARA O CONTRATO.
                //rwaAddress.sellRWA(colateralOwner.owner, 0, colateralOwner.coleteralId, ""); AQUI EU PRECISARIA REGISTRAR O RWA NA OPENSEA, POR EXEMPLO.
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

    /* handle a received message*/
    function _ccipReceive( Client.Any2EVMMessage memory any2EvmMessage) internal override /*onlyWhitelistedSourceChain(any2EvmMessage.sourceChainSelector) onlyWhitelistedSenders(abi.decode(any2EvmMessage.sender, (address)))*/ {
        lastReceivedMessageId = any2EvmMessage.messageId; // fetch the messageId
        lastReceivedText = abi.decode(any2EvmMessage.data, (bytes)); // abi-decoding of the sent text

        bytes32 permissionHash;
        uint _ensuranceValue;
        bool _colateralLocked;

        (permissionHash, _ensuranceValue, _colateralLocked) = abi.decode(lastReceivedText, (bytes32, uint, bool));

        handlePermission(permissionHash, _ensuranceValue, _colateralLocked);

        emit MessageReceived( any2EvmMessage.messageId, any2EvmMessage.sourceChainSelector, abi.decode(any2EvmMessage.sender, (address)), abi.decode(any2EvmMessage.data, (string)));
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
