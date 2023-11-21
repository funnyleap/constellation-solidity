// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <=0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract BellumVRF is Ownable, VRFConsumerBaseV2 {

    event RequestSent(uint requestId, uint32 numWords, uint _titleId, uint _drawNumber, uint _totalPlayersAvailable);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords, uint randomValue);
    event RandomValueUpdated(uint256 randomValue);

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
        uint256 randomValue;
    }
    struct DrawInfos{
        uint titleId;
        uint drawNumber;
        uint totalPlayersAvailable;
    }

    mapping(uint256 requestId => RequestStatus) public s_requests;
    mapping(uint256 requestId => DrawInfos) public s_draw;

    //State variable
    uint256 private randomValue;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;
    
    VRFCoordinatorV2Interface COORDINATOR;
    address vrfCoordinator;
    bytes32 keyHash;
    uint64 s_subscriptionId;
    uint32 callbackGasLimit;
    uint16 requestConfirmations;
    uint32 numWords;

    constructor(address _vrfCoordinator, //0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
                bytes32 _keyHash, //0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f
                uint64 _subscriptionId, //5413
                uint32 _callbackGasLimit, //100000
                uint16 _requestConfirmations, //3
                uint32 _numWords //1
               ) VRFConsumerBaseV2(_vrfCoordinator){
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        s_subscriptionId = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords;
    }

    function requestRandomWords(uint _titleId, uint _drawNumber, uint256 _totalPlayersAvailable) external returns (uint256 requestId) {
 
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

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].exists, "request not found");

        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords ;
        s_requests[_requestId].randomValue = (_randomWords[0] % s_draw[_requestId].totalPlayersAvailable)+1;

        emit RequestFulfilled(_requestId, _randomWords, s_requests[_requestId].randomValue);
    }

    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords, uint256 _randomValue) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords, request.randomValue);
    }
}