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
        address nftOwner;
        uint ensuranceValue;
        ERC721 colateralAddress;
        uint colateralId;
        bool colateralLocked;
        bool isPermission;
    }

    //Array to keep track of NFT's prices
    Permissions[] colateralAddresses;

    // Mapping to keep track of whitelisted source chains.
    mapping(uint64 => bool) public whitelistedSourceChains;
    // Mapping to keep track of whitelisted senders.
    mapping(address => bool) public whitelistedSenders;
    // Mapping to keep track of colateral permissions
    mapping(bytes32 => Permissions) public permissionsInfo;

    
    // Event emitted when a message is received from another chain.
    event MessageReceived( bytes32 indexed messageId, uint64 indexed sourceChainSelector, address sender, string text);
    event EnsuranceAdd(address provisoryOwner, uint _nftId, uint _titleId, uint _drawNumber);
    event NFTRefunded(uint _titleId, uint _drawNumber, address _nftOwner, uint _colateralId);
    event NFTPriceAtMoment(uint _contractId, ERC721 _colateralAddresses, int _nftValue, uint _referenceValue);
    event PriceLowEvent(uint _contractId, ERC721 _colateralAddresses, int _nftValue, uint _referenceValue);

    LinkTokenInterface linkToken = LinkTokenInterface();//FALTA O ENDEREÇO
    HorizonFujiS sender = HorizonFujiS(payable());//FALTA O ENDEREÇO
    ERC721 nft;

    constructor(address _router) CCIPReceiver(_router) { //FALTA O ENDEREÇO
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
            nftOwner: address(0),
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
                sendNftBackToOwner(_permissionHash);
            }
        }
    }

    function addCollateral(uint256 _titleId, uint _contractId, uint _drawNumber, uint _nftId, ERC721 _colectionAddress) public {
        bytes32 permissionHash = keccak256(abi.encodePacked(_titleId, _contractId, _drawNumber));

        require(permissionsInfo[permissionHash].isPermission == true, "This permission didn't exists!");

        Permissions storage permission = permissionsInfo[permissionHash];

        permission.idTitle = _titleId;
        permission.contractId = _contractId;
        permission.drawNumber = _drawNumber;
        permission.nftOwner = msg.sender;
        permission.colateralId = _nftId;
        permission.colateralAddress = _colectionAddress;

        colateralAddresses.push(permission);

        //Só para teste
        uint colateralPrice = 100 * 10**18;
        uint targetPrice = permission.ensuranceValue;

        require(uint(colateralPrice) >= targetPrice.mul(10), "The ensurance must have at least 10 times the value of the value needed!");
        
        nft = _colectionAddress;
        nft.transferFrom(msg.sender, address(this), _nftId);

        address provisoryOwner = nft.ownerOf(_nftId);

        bytes memory colateralAdded = abi.encode(permissionHash, _colectionAddress, _nftId);

        sender.sendMessagePayLINK(12532609583862916517, polygonReceiver, colateralAdded);

        emit EnsuranceAdd(provisoryOwner, _nftId, _titleId, _drawNumber);
    }

    function sendNftBackToOwner(bytes32 _permissionHash) internal{
        require(permissionsInfo[_permissionHash].isPermission == true, "This permission didnt exists!");

        Permissions storage permission = permissionsInfo[_permissionHash];

        nft = permission.colateralAddress;

        nft.safeTransferFrom(address(this), permission.nftOwner, permission.colateralId);

        emit NFTRefunded(permission.idTitle, permission.drawNumber, permission.nftOwner, permission.colateralId);
    }

    //Tem de reformular com o Functions
    function checkColateralPrice(bytes32 _permissionHash) internal {
        for (uint256 i = 0; i < colateralAddresses.length; i++) {
            // Obter o valor atual do NFT
            int256 nftValue = 100 * 10**18;
            
            Permissions storage permission = permissionsInfo[_permissionHash];
            
            // Valor de referência
            uint256 referenceValue = permission.ensuranceValue;

            if (uint(nftValue) >= referenceValue.mul(10)) {
                emit NFTPriceAtMoment(permission.contractId, colateralAddresses[i].colateralAddress, nftValue, referenceValue);
            } else if (uint(nftValue) >= referenceValue.mul(6)) {
                // O EVENTO ABAIXO IRÁ 'ALERTAR' O FRONTEND QUE, POR SUA VEZ, IRÁ COMUNICAR O DONO DO NFT QUE ELE PRECISA TOMAR PROVIDENCIA.
                emit PriceLowEvent(permission.contractId, colateralAddresses[i].colateralAddress, nftValue, referenceValue);
            } else if (uint(nftValue) < referenceValue.mul(3)) {
                //address nftAddress = colateralAddresses[i]; PRECISO DESCOBRIR SE SERÁ POSSÍVEL MANTER O NFT NA CARTEIRA DO DONO OU PRECISAREI TRANSFERIR PARA O CONTRATO.
                //nftAddress.sellNFT(colateralOwner.owner, 0, colateralOwner.coleteralId, ""); AQUI EU PRECISARIA REGISTRAR O NFT NA OPENSEA, POR EXEMPLO.
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
    // modifier onlyWhitelistedSourceChain(uint64 _sourceChainSelector) {
    //     if (!whitelistedSourceChains[_sourceChainSelector])
    //         revert SourceChainNotWhitelisted(_sourceChainSelector);
    //     _;
    // }

    // modifier onlyWhitelistedSenders(address _sender) {
    //     if (!whitelistedSenders[_sender]) revert SenderNotWhitelisted(_sender);
    //     _;
    // }
}
