// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

contract HorizonS is CCIPReceiver {

    // Custom errors to provide more descriptive revert messages.
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
    error NothingToWithdraw();
    error FailedToWithdrawEth(address owner, address target, uint256 value);
    error DestinationChainNotWhitelisted(uint64 destinationChainSelector);

    // Event emitted when a message is sent to another chain.
    event MessageSent(bytes32 indexed messageId, uint64 indexed destinationChainSelector, address receiver, bytes text, address feeToken, uint256 fees);
    event MessageReceived(bytes32 indexed messageId, uint64 indexed sourceChainSelector, address sender, string text, address token, uint256 tokenAmount);
    event CCIPReceiverAdded(string blockchainName, address receiverAddress);
    event CCIPReceiverRemoved(address _receiverAddress);

    bytes32 private lastReceivedMessageId;
    string private lastReceivedText;
    uint private destinationChainSelector;

    address owner;

    /* STRUCTS */
    struct ReceiverInfo {
        string blockchainName;
        address receiverAddress;
        bool isReceiver;
    }

    // Mapping to keep track of whitelisted destination chains.
    mapping(uint64 => bool) public whitelistedDestinationChains;
    // Mapping to keep track of receivers.
    mapping(address receiverAddress => ReceiverInfo) public ccipReceicers;

    LinkTokenInterface linkToken = LinkTokenInterface(0x5FA769922a6428758fb44453815e2c436c57C3c7);  //

    constructor(address _router, //0x70499c328e1e2a3c41108bd3730f6670a44595d1
                address _linkToken //0x326C977E6efc84E512bB9C30f76E30c160eD06FB
               ) CCIPReceiver(_router){ 
        linkToken = LinkTokenInterface(_linkToken);
        owner = msg.sender;
    }

    /// @dev Whitelists a chain for transactions.
    /// @notice This function can only be called by the owner.
    /// @param _destinationChainSelector The selector of the destination chain to be whitelisted.
    function whitelistDestinationChain(uint64 _destinationChainSelector) external onlyOwner {
        whitelistedDestinationChains[_destinationChainSelector] = true;
    }

    /// @dev Denylists a chain for transactions.
    /// @notice This function can only be called by the owner.
    /// @param _destinationChainSelector The selector of the destination chain to be denylisted.
    function denylistDestinationChain(uint64 _destinationChainSelector) external onlyOwner {
        whitelistedDestinationChains[_destinationChainSelector] = false;
    }

    function addReceiver(string memory _blockchainName, address _receiverAddress) public onlyOwner{
        require(_receiverAddress != address(0), "Enter a valid address!");
        require(ccipReceicers[_receiverAddress].isReceiver == false, "Receiver is already registered!");

        ReceiverInfo memory newReceiver = ReceiverInfo({
            blockchainName: _blockchainName,
            receiverAddress: _receiverAddress,
            isReceiver: true
        });
        
        ccipReceicers[_receiverAddress] = newReceiver;

        emit CCIPReceiverAdded(_blockchainName, _receiverAddress);
    }

    function removeReceiver(address _receiverAddress) public onlyOwner {
        require(ccipReceicers[_receiverAddress].isReceiver == true, "Receiver is already registered!");

        delete ccipReceicers[_receiverAddress];

        emit CCIPReceiverRemoved(_receiverAddress);
    }

    function sendMessagePayLINK(uint64 _destinationChainSelector, address _receiverAddress, bytes memory _data) external /*onlyOwner*/ returns (bytes32 messageId){
        require(ccipReceicers[_receiverAddress].receiverAddress != address(0), "Enter a valid receiver address!");
        require(ccipReceicers[_receiverAddress].isReceiver == true, "This receiver is not whitelisted yet!");

        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            ccipReceicers[_receiverAddress].receiverAddress,
            _data,
            address(linkToken)
        );

        IRouterClient router = IRouterClient(this.getRouter());

        uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);

        if (fees > linkToken.balanceOf(address(this)))
            revert NotEnoughBalance(linkToken.balanceOf(address(this)), fees);

        linkToken.approve(address(router), fees);

        messageId = router.ccipSend(_destinationChainSelector, evm2AnyMessage);

        emit MessageSent(messageId, _destinationChainSelector, _receiverAddress, _data, address(0), fees);

        return messageId;
    }

    function _buildCCIPMessage(address _receiver, bytes memory _data, address _feeTokenAddress) internal pure returns (Client.EVM2AnyMessage memory) {
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: abi.encode(_data),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs:  Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 800_000, strict: false})
            ),
            feeToken: _feeTokenAddress
        });
        return evm2AnyMessage;
    }

    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal override{
        lastReceivedMessageId = any2EvmMessage.messageId;
        lastReceivedText = abi.decode(any2EvmMessage.data, (string));

        emit MessageReceived(any2EvmMessage.messageId, any2EvmMessage.sourceChainSelector, abi.decode(any2EvmMessage.sender, (address)), abi.decode(any2EvmMessage.data, (string)), any2EvmMessage.destTokenAmounts[0].token, any2EvmMessage.destTokenAmounts[0].amount);
    }

    receive() external payable {}

    function withdraw(address _beneficiary) public /*onlyOwner*/ {
        uint256 amount = address(this).balance;

        if (amount == 0) revert NothingToWithdraw();

        (bool sent, ) = _beneficiary.call{value: amount}("");

        if (!sent) revert FailedToWithdrawEth(msg.sender, _beneficiary, amount);
    }

    function withdrawToken( address _beneficiary, address _token) public /*onlyOwner*/ {
        uint256 amount = IERC20(_token).balanceOf(address(this));

        if (amount == 0) revert NothingToWithdraw();

        IERC20(_token).transfer(_beneficiary, amount);
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only Owner can call this function!");
        _;
    }
}
