// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <=0.8.20;

import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

/**
 * @title Horizon VRF
 * @author Barba
 * @notice Chainlink VRF contract adaptted to Horizon needs 
 */
contract HorizonVRF is VRFConsumerBaseV2, OwnerIsCreator {

    /// @notice Event emitted when a request is send
    event RequestSent(uint requestId, uint32 numWords, uint _titleId, uint _drawNumber, uint _totalPlayersAvailable);
    /// @notice Event emitted when a request is fulfilled
    event RequestFulfilled(uint256 requestId, uint256[] randomWords, uint randomValue);
    /// @notice Event emitted when the random value is processed
    event RandomValueUpdated(uint256 randomValue);
    
    /// @notice Struct to Requests Infos
    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
        uint256 randomValue;
    }
    /// @notice Struct to Draw infos
    struct DrawInfos{
        uint titleId;
        uint drawNumber;
        uint totalPlayersAvailable;
    }
    
    // map rollers to requestIds
    mapping(uint256 requestId => RequestStatus) public s_requests;
    // map vrf results to rollers
    mapping(uint256 requestId => DrawInfos) public s_draw;

    //State variable
    uint256 private randomValue;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;
    
    /// @dev Mumbai coordinator. For other networks,
    VRFCoordinatorV2Interface COORDINATOR;
    address vrfCoordinator;
    /// @dev The gas lane to use, which specifies the maximum gas price to bump to.
    bytes32 keyHash;
    /// @dev Subscription ID.
    uint64 s_subscriptionId;
    /// @dev The maximum limit of gas
    uint32 callbackGasLimit;
    /// Number of confirmations. Default is 3. 
    uint16 requestConfirmations;
    /// Number of verifyable random numbers you need
    uint32 numWords;

    constructor(address _vrfCoordinator,
                bytes32 _keyHash,
                uint64 _subscriptionId,
                uint32 _callbackGasLimit,
                uint16 _requestConfirmations,
                uint32 _numWords
               ) VRFConsumerBaseV2(_vrfCoordinator){
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        s_subscriptionId = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords;
    }

    /**
     * @notice This function send a VRF request
     * @param _titleId The number of the Consórcio Title that is requesting VRF
     * @param _drawNumber The draw number that is happening
     * @param _totalPlayersAvailable The total number of eligiable participants of this particular draw
     */
    function requestRandomWords(uint _titleId, uint _drawNumber, uint256 _totalPlayersAvailable) external  onlyOwner returns (uint256 requestId) {
 
        requestId = COORDINATOR.requestRandomWords(keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, numWords);
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false,
            randomValue: 0
        });

        requestIds.push(requestId);
        lastRequestId = requestId;

        s_draw[requestId] = DrawInfos({
            titleId: _titleId,
            drawNumber: _drawNumber,
            totalPlayersAvailable: _totalPlayersAvailable
        });

        emit RequestSent(requestId, numWords, _titleId, _drawNumber, _totalPlayersAvailable);
        return requestId;
    }
    /**
     * @notice This is a callback function
     * @param _requestId The request ID
     * @param _randomWords The numbers requested
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].exists, "request not found");

        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords ;
        s_requests[_requestId].randomValue = (_randomWords[0] % s_draw[_requestId].totalPlayersAvailable)+1;

        emit RequestFulfilled(_requestId, _randomWords, s_requests[_requestId].randomValue);
    }

    /**
     * @notice This function returns the info about the requestId informed
     * @param _requestId The Id of the request needed
     * @return fulfilled The confirmation about the request existence
     * @return randomWords The random words received
     * @return _randomValue The random value received
     */
    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords, uint256 _randomValue) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords, request.randomValue);
    }
}