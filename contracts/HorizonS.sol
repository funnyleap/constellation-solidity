// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";

/**
 * @title Horizon Sender
 * @author Barba
 * @notice This contract receive data from Horizon main contract and dispatch through CCIP
 */
contract HorizonS is CCIPReceiver, OwnerIsCreator  {

    ///@notice Custom chainlink errors to provide more descriptive revert messages.
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
    error NothingToWithdrawal();
    error FailedToWithdrawalEth(address owner, address target, uint256 value);
    error DestinationChainNotWhitelisted(uint64 destinationChainSelector);

    // Event emitted when a message is sent to another chain.
    event MessageSent(bytes32 indexed messageId, uint64 indexed destinationChainSelector, address receiver, bytes text, address feeToken, uint256 fees);

    /**
     * @dev CCIP variables
     */
    bytes32 private lastReceivedMessageId;
    string private lastReceivedText;
    uint private destinationChainSelector;

    // Mapping to keep track of whitelisted destination chains.
    mapping(uint64 => bool) public whitelistedDestinationChains;

    LinkTokenInterface linkToken = LinkTokenInterface(0x5FA769922a6428758fb44453815e2c436c57C3c7);

    /**
     * 
     * @param _router Fuji router address
     * @param _linkToken Fuji Link token address
     */
    constructor(address _router,
                address _linkToken
               ) CCIPReceiver(_router){ 
        linkToken = LinkTokenInterface(_linkToken);
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

    /**
     * @notice This function encrypts and send the message to Fuji
     * @param _destinationChainSelector CCIP blockchain identificator
     * @param _receiverAddress The address of the receiver
     * @param _data The data that must be send
     */
    function sendMessagePayLINK(uint64 _destinationChainSelector, address _receiverAddress, bytes memory _data) external onlyWhitelistedDestinationChain(_destinationChainSelector) onlyOwner returns (bytes32 messageId){

        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            _receiverAddress,
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

    /**
     * @notice this function is responsable to build the message that will be send
     * @param _receiver receiver address in Fuji
     * @param _data the values that must be send
     * @param _feeTokenAddress the address of the token used to pay the chainlink fees.
     * @dev _feeTokenAddress is mandatory only if using Link.
     */
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

    /**
     * @notice this function receive the encoded message
     * @param any2EvmMessage the constructed message
     */
    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal override{
        lastReceivedMessageId = any2EvmMessage.messageId;
        lastReceivedText = abi.decode(any2EvmMessage.data, (string));
    }

    receive() external payable {}

    /**
     * @notice Regular Chainlink Withdrawal function
     * @param _beneficiary The address that will receive the Withdrawal value
     */
    function withdrawal(address _beneficiary) public  onlyOwner {
        uint256 amount = address(this).balance;

        if (amount == 0) revert NothingToWithdrawal();

        (bool sent, ) = _beneficiary.call{value: amount}("");

        if (!sent) revert FailedToWithdrawalEth(msg.sender, _beneficiary, amount);
    }

    /**
     * @notice Regular Chainlink Withdrawal function
     * @param _beneficiary  The address that will receive the Withdrawal value
     * @param _token The token that you want to Withdrawal
     */
    function withdrawalToken( address _beneficiary, address _token) public  onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));

        if (amount == 0) revert NothingToWithdrawal();

        IERC20(_token).transfer(_beneficiary, amount);
    }

    /* MODIFIER */
    
    /// @dev Modifier that checks if the chain with the given destinationChainSelector is whitelisted.
    /// @param _destinationChainSelector The selector of the destination chain.
    modifier onlyWhitelistedDestinationChain(uint64 _destinationChainSelector) {
        if (!whitelistedDestinationChains[_destinationChainSelector])
            revert DestinationChainNotWhitelisted(_destinationChainSelector);
        _;
    }
}
