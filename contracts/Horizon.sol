// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <=0.8.20;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {HorizonS} from "./HorizonS.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./HorizonStaff.sol";
import "./HorizonVRF.sol";
import "./HorizonReceipt.sol";

error SourceChainNotWhitelisted(uint64 sourceChainSelector);
error FailedToWithdrawEth(address owner, address target, uint256 value);
error SenderNotWhitelisted(address sender);

contract Horizon is CCIPReceiver{

    /* CCIP */
    bytes32 private lastReceivedMessageId;
    bytes private lastReceivedText;
    mapping(uint64 => bool) public whitelistedSourceChains;
    mapping(address => bool) public whitelistedSenders;

    uint titleId = 0;
    uint paymentDelay;
    address fujiReceiver;
    address owner;

    event NewTitleCreated(uint _titleId, uint _scheduleId, uint _monthlyValue, uint _titleValue);
    event TitleStatusUpdated(TitleStatus status);
    event NewTitleSold(uint _contractId, address _owner);
    event AmountToPay(uint amountWithInterests);
    event InstallmentPaid(uint _idTitle, uint _contractId, uint _installmentsPaid);
    event EnsuranceValueNeededUpdate(uint _idTitle, uint _contractId, uint _valueOfEnsurance);
    event EnsuranceUpdated(address _temporaryEnsurance);
    event NextDraw(uint _nextDraw);
    event VRFAnswer(bool fulfilled, uint256[] randomWords, uint randomValue);
    event MonthlyWinnerSelected(uint _idTitle, uint _drawNumber, uint _randomValue, uint _selectedContractId, address _winner);
    event ColateralTitleAdded(uint _idTitle, uint _contractId, uint _drawNumber, uint _idOfColateralTitle, uint _idOfColateralContract);
    event CreatingPermission(uint _idTitle, uint _contractId, uint _drawSelected, address _fujiReceiver);
    event MonthlyWinnerPaid(uint _idTitle, uint _drawNumber, address _winner, uint _titleValue);
    event MyTitleStatusUpdated(MyTitleWithdraw myTitleStatus);
    event PaymentLateNumber(uint _i);
    event AmountLateWithInterest(uint totalAmountLate);
    event PaymentIsLate(uint lateInstallments);
    event ThereAreSomePendencies(uint _installmentsPaid, uint _colateralTitleId, address _colateralTitleAddress, address colateralRWAAddress, MyTitleWithdraw myTitleStatus);
    event LastInstallmentPaid(uint _installmentsPaid);
    event NewInvestmentCreated(uint _investmentValue, address _protocolAddress);
    event ThisTitleHasBeenCanceled(uint _titlesAvailableForNextDraw);
    event MessageReceived( bytes32 indexed messageId, uint64 indexed sourceChainSelector, address sender, string text);

    enum TitleStatus{
        Canceled, //0
        Closed, //1
        Finalized, //2
        Open, //3
        Waiting //4
    }

    TitleStatus status;

    enum MyTitleWithdraw{
        Canceled, //0
        Late, //1
        OnSchedule, //2
        Withdraw,
        Finalized //3
    }

    MyTitleWithdraw myTitleStatus;

    struct Titles {
        uint openSellingDate;
        uint closeSellingDate;
        uint paymentSchedule;
        uint nextDrawNumber;
        uint titleValue;
        uint installments;
        uint monthlyInvestiment;
        uint protocolFee;
        uint numberOfTitlesSold;
        uint totalValueReceived;
        uint totalValuePaid;
        uint titleCanceled;
        TitleStatus status;
    }

    struct TitlesSold {
        uint contractId;
        uint titleValue;
        uint installments;
        uint monthlyValue;
        uint periodLocked;
        address titleOwner;
        uint installmentsPaid;
        uint drawSelected;
        uint colateralId;
        address colateralTitleAddress;
        address colateralRWAAddress;
        uint valueOfEnsuranceNeeded;
        MyTitleWithdraw myTitleStatus;
        bool paid;
    }

    struct TitleRecord {
        uint contractId;
        uint256 installmentNumber;
        uint paymentDate;
        address payerAddress;
        address user;
        uint amount;
        uint paymentDelay;
        bool paid;
        uint installmentsPaid;
    }

    struct Draw {
        uint idTitle;
        uint drawNumber;
        uint drawDate;
        uint totalParticipants;
        uint requestId;
        uint randomNumberVRF;
        uint selectedContractID;
        address winner;
    }

    struct ColateralTitles {
        address colateralOwner;
        uint titleIdOfColateral;
        uint contractIdOfColateral;
    }

    struct FujiPermissions{
        uint idTitle;
        uint contractId;
        uint drawNumber;
    }
    
    IERC20 stablecoin;
    IERC721 nftToken;

    HorizonStaff staff = HorizonStaff(0x29b8eF8f8062071C5323c37FB95D30111f198404);
    HorizonVRF vrfv2consumer = HorizonVRF(0xA75447C1A6dD04dA5cEB791023fa7192cc577CFa);
    HorizonS sender = HorizonS(payable(0x55a5214740Ce71c80B9f91390276a0AE0e063911));

    mapping(uint titleId => Titles) public allTitles;
    mapping(uint titleId => mapping(uint contractId => TitlesSold)) public titleSoldInfos;
    mapping(uint titleId => mapping(uint drawNumber => Draw)) public drawInfos;
    mapping(uint titleId => mapping(uint drawNumber => mapping(uint paymentOrderOrRandomValue => TitleRecord))) public selectorVRF;
    mapping(bytes32 permissionHash => FujiPermissions) permissionInfo;
    mapping(uint titleId => mapping(uint contractId => ColateralTitles)) public colateralInfos;

    constructor(address _router) CCIPReceiver(_router){ //0x70499c328e1e2a3c41108bd3730f6670a44595d1
        owner = msg.sender;
    }

    function createTitle(uint _opening, //Working Nice
                         uint _closing,
                         uint _participants,
                         uint _value) public {
        require(_opening != 0, "Must Select a date to start to sell the titles!");
        require(_closing > _opening, "Must Select a date to stop to sell the titles!");
        require(_participants != 0, "Must set the number of total participants!");

        titleId++;

        uint scheduleId = staff.createSchedule( titleId, _participants, _closing);

        Titles memory newTitle = Titles ({
        openSellingDate:_opening,
        closeSellingDate: _closing,
        paymentSchedule: scheduleId,
        nextDrawNumber: 1,
        titleValue: _value * 10 ** 18,
        installments: _participants,
        monthlyInvestiment: (_value * 10 ** 18) / (_participants),
        protocolFee: (((_value * 10 ** 18) / _participants) * 5) / 100,
        numberOfTitlesSold: 0,
        totalValueReceived: 0,
        totalValuePaid: 0,
        titleCanceled: 0,
        status: TitleStatus.Waiting
        });

        allTitles[titleId] = newTitle;

        uint monthlyValue = (allTitles[titleId].monthlyInvestiment + (allTitles[titleId].protocolFee));

        emit NewTitleCreated(titleId, scheduleId, monthlyValue, allTitles[titleId].titleValue);
    }

    function updateTitleStatus(uint _titleId) public { //Working Nice
        Titles storage title = allTitles[_titleId];

        require(title.status == TitleStatus.Waiting || title.status == TitleStatus.Open || title.status == TitleStatus.Closed, "This title already ended");

        if(block.timestamp > title.openSellingDate && title.status == TitleStatus.Waiting){
            title.status = TitleStatus.Open;

            emit TitleStatusUpdated(title.status);
        }else{
            if(block.timestamp > title.closeSellingDate && title.status == TitleStatus.Open){
                title.status = TitleStatus.Closed;

            }else{
                uint nextDrawParticipants = staff.returnDrawParticipants(_titleId, title.nextDrawNumber);

                if( title.status == TitleStatus.Closed && title.nextDrawNumber > title.installments ||
                    title.status == TitleStatus.Closed && title.nextDrawNumber + (title.titleCanceled) > title.installments && nextDrawParticipants == 0){
                    title.status = TitleStatus.Finalized;

                    emit TitleStatusUpdated(title.status);
                }else{
                    if(title.numberOfTitlesSold == 0){
                        title.status = TitleStatus.Canceled;

                        emit ThisTitleHasBeenCanceled(nextDrawParticipants);
                    }
                }
            }
        }
    }

    function buyTitle(uint64 _titleId, bool withdrawPeriod, IERC20 _tokenAddress) public { //Working Nice
        Titles storage title = allTitles[_titleId];

        require(title.status == TitleStatus.Open,"This Title is not available. Check the Title status!");
        require(title.numberOfTitlesSold <= title.installments, "Title soldout!");

        title.numberOfTitlesSold++;
        //Se você deseja sacar o valor do titulo em menos de 5 meses, se sorteado. Marque como true.
        uint fee;
        uint lockPeriod;
        if(withdrawPeriod == true){
            fee = title.protocolFee;
            lockPeriod = 0;
        } else {
            fee = 0;
            lockPeriod = 5;
        }

        TitlesSold memory myTitle = TitlesSold({
            contractId: title.numberOfTitlesSold,
            titleValue: title.titleValue,
            installments: title.installments,
            monthlyValue: ((title.monthlyInvestiment) + (fee)),
            periodLocked: lockPeriod,
            titleOwner: msg.sender,
            installmentsPaid: 0,
            drawSelected: 0,
            colateralId: 0,
            colateralTitleAddress: address(0),
            colateralRWAAddress: address(0),
            valueOfEnsuranceNeeded: 0,
            myTitleStatus: MyTitleWithdraw.OnSchedule,
            paid: false
        });

        titleSoldInfos[_titleId][title.numberOfTitlesSold] = myTitle;

        if(title.numberOfTitlesSold > title.installments){
            title.status = TitleStatus.Closed;
        }

        payInstallment(_titleId, title.numberOfTitlesSold, _tokenAddress);

        emit NewTitleSold(title.numberOfTitlesSold, msg.sender);
    }

    function payInstallment(uint _idTitle, //
                            uint _contractId,
                            IERC20 _tokenAddress) public {
        Titles storage title = allTitles[_idTitle];
        TitlesSold storage myTitle = titleSoldInfos[_idTitle][_contractId];
        require(title.status == TitleStatus.Closed || title.status == TitleStatus.Open, "Check the title status!");
        require(myTitle.myTitleStatus == MyTitleWithdraw.OnSchedule || myTitle.myTitleStatus == MyTitleWithdraw.Late || myTitle.myTitleStatus == MyTitleWithdraw.Withdraw );
        require(myTitle.installmentsPaid < title.installments, "You already paid all the installments!");

        uint _installment;

        if(myTitle.installmentsPaid > 0 ){
            _installment = (myTitle.installmentsPaid + 1);
        }

        uint paymentDate = staff.returnPaymentDeadline(title.paymentSchedule, _installment);
        uint amountToPay;

        if(block.timestamp > paymentDate && myTitle.installmentsPaid > 0 ){
            paymentDelay = (block.timestamp - paymentDate);

            if(paymentDelay > 0){

                amountToPay = staff.calculateDelayedPayment(paymentDelay, title.paymentSchedule, myTitle.monthlyValue);

                emit AmountToPay(amountToPay);

                receiveInstallment(_idTitle, _contractId, amountToPay, _tokenAddress);
            }
        }else{
            amountToPay = myTitle.monthlyValue;
            
            emit AmountToPay(amountToPay);

            receiveInstallment(_idTitle, _contractId, amountToPay, _tokenAddress);
        }

        if(myTitle.installmentsPaid >= title.nextDrawNumber && myTitle.drawSelected == 0){

            TitleRecord memory record = TitleRecord({
                contractId: _contractId,
                installmentNumber: _installment,
                paymentDate: block.timestamp,
                payerAddress: msg.sender,
                user: myTitle.titleOwner,
                amount: amountToPay,
                paymentDelay: paymentDelay,
                paid: true,
                installmentsPaid: myTitle.installmentsPaid
            });
            
            uint nextDrawParticipants = staff.addParticipantsToDraw(title.paymentSchedule, title.nextDrawNumber);

            selectorVRF[_idTitle][_installment][nextDrawParticipants] = record;
        }

        if(myTitle.installmentsPaid == myTitle.installments){
            myTitle.myTitleStatus = MyTitleWithdraw.Withdraw;

            if(myTitle.colateralId != 0 ){
                refundColateral(_idTitle, _contractId);
            }
        }
        if(myTitle.installmentsPaid == title.nextDrawNumber &&  myTitle.myTitleStatus == MyTitleWithdraw.Late){
            myTitle.myTitleStatus = MyTitleWithdraw.OnSchedule;
        }

        updateValueOfEnsurance(_idTitle, _contractId);

        emit InstallmentPaid(_idTitle, _contractId, myTitle.installmentsPaid);
    }

    function receiveInstallment(uint _idTitle, uint _contractId, uint _amountToPay, IERC20 _tokenAddress) internal{ //Working Nice
        TitlesSold storage myTitle = titleSoldInfos[_idTitle][_contractId];
        Titles storage title = allTitles[_idTitle];
        require(myTitle.contractId <= title.numberOfTitlesSold, "Enter a valid contract Id for this Title!");
        require(myTitle.myTitleStatus != MyTitleWithdraw.Canceled || myTitle.myTitleStatus != MyTitleWithdraw.Finalized, "your title already have been finalized or canceled. Please check the status.");
        require(address(_tokenAddress) != address(0), "Enter a token address");

        (, , bool isStable) = staff.returnAvailableStablecoin(_tokenAddress);

        require(isStable == true , "Token not allowed!");

        stablecoin = _tokenAddress;

        require(_amountToPay >= myTitle.monthlyValue, "Wrong value!!");

        //Valida se o endereço tem o valor da parcela na carteira.
        require(stablecoin.balanceOf(msg.sender)>= _amountToPay, "Insufficient balance");

        //Valida se o contrato(esse), tem permissão para realizar a transferência do valor.
        require(stablecoin.allowance(msg.sender, address(this)) >= _amountToPay, "You must approve the contract to transfer the tokens");

        myTitle.installmentsPaid++;

        if(myTitle.periodLocked == 0){
            title.totalValueReceived = title.totalValueReceived + title.monthlyInvestiment;
            
            stablecoin.transferFrom(msg.sender, address(this), title.monthlyInvestiment);
            stablecoin.transferFrom(msg.sender, address(staff), (_amountToPay - title.monthlyInvestiment));
        } else{
            title.totalValueReceived = title.totalValueReceived + title.monthlyInvestiment;

            if(_amountToPay - title.monthlyInvestiment > 0){
            
                stablecoin.transferFrom(msg.sender, address(this), title.monthlyInvestiment);
                stablecoin.transferFrom(msg.sender, address(staff), (_amountToPay - title.monthlyInvestiment));
            } else{
                stablecoin.transferFrom(msg.sender, address(this), _amountToPay);
            }
        }
    }

    function updateValueOfEnsurance(uint _idTitle, uint _contractId) internal {//Working Nice
        Titles storage titles = allTitles[_idTitle];
        TitlesSold storage myTitle = titleSoldInfos[_idTitle][_contractId];

        uint valueAlreadyPaid = (myTitle.installmentsPaid * titles.monthlyInvestiment);

        if(valueAlreadyPaid >= myTitle.titleValue){
            myTitle.valueOfEnsuranceNeeded = 0;
        }else{
            myTitle.valueOfEnsuranceNeeded = myTitle.titleValue - valueAlreadyPaid;
        }

        emit EnsuranceValueNeededUpdate(_idTitle, _contractId, myTitle.valueOfEnsuranceNeeded);
    }

    function monthlyVRFWinner(uint _idTitle) public { //Working Nice
        Titles storage title = allTitles[_idTitle];

        require(title.nextDrawNumber <= title.installments, "All the draws already ocurred!");

        uint thisDrawDate = staff.returnDrawDate(title.paymentSchedule, title.nextDrawNumber);

        require(block.timestamp > thisDrawDate, "Isn't the time yet!");

        uint nextDrawParticipants = staff.returnDrawParticipants(title.paymentSchedule, title.nextDrawNumber);

        require(nextDrawParticipants > 0, "There is no participantes available for the draw!");

        uint256 requestId = vrfv2consumer.requestRandomWords(_idTitle, title.nextDrawNumber, nextDrawParticipants);

        title.status = TitleStatus.Waiting;

        Draw memory draw = Draw({
            idTitle: _idTitle,
            drawNumber: title.nextDrawNumber,
            drawDate: block.timestamp,
            totalParticipants: nextDrawParticipants,
            requestId: requestId,
            randomNumberVRF: 0,
            selectedContractID: 0,
            winner: address(0)
        });

        drawInfos[_idTitle][title.nextDrawNumber] = draw;

        if(title.nextDrawNumber > title.installments){
            title.status = TitleStatus.Finalized;
        }
    }

    function receiveVRFRandomNumber(uint256 _idTitle) public{
        Titles storage title = allTitles[_idTitle];
        Draw storage draw = drawInfos[_idTitle][title.nextDrawNumber];

        (bool fulfilled, uint256[] memory randomWords, uint256 randomValue) = vrfv2consumer.getRequestStatus(draw.requestId);

        require(fulfilled, "VRF request not fulfilled");
        
        emit VRFAnswer(fulfilled, randomWords, randomValue);

        TitleRecord storage winningTicket = selectorVRF[_idTitle][draw.drawNumber][randomValue];

        draw.randomNumberVRF = randomValue;
        draw.selectedContractID = winningTicket.contractId;
        draw.winner = winningTicket.user;

        TitlesSold storage myTitle = titleSoldInfos[_idTitle][winningTicket.contractId];

        myTitle.drawSelected = draw.drawNumber;

        updateValueOfEnsurance(_idTitle, winningTicket.contractId);

        title.status = TitleStatus.Closed;

        title.nextDrawNumber++;

        emit MonthlyWinnerSelected(_idTitle, draw.drawNumber, randomValue, winningTicket.contractId, winningTicket.user);
    }

    function addTitleAsColateral(uint _titleId, uint _contractId, uint _idOfColateralTitle, uint _idOfColateralContract) public{ //OK
        TitlesSold storage myColateralTitle = titleSoldInfos[_idOfColateralTitle][_idOfColateralContract];
        TitlesSold storage myTitle = titleSoldInfos[_titleId][_contractId]; 

        require(myTitle.drawSelected != 0, "You haven't been selected yet!");
        require(myTitle.titleOwner == msg.sender, "Only the owner can add a colateral!");
        require(myColateralTitle.titleOwner == msg.sender, "Only the owner can add a colateral!");
        require(myColateralTitle.titleValue >= myTitle.valueOfEnsuranceNeeded, "The colateral total value must be greater than tue ensuranceValueNeeded");
        
        uint colateralValuePaid = myColateralTitle.installmentsPaid * myColateralTitle.monthlyValue;
        uint ensuranceNeeded = myTitle.valueOfEnsuranceNeeded * 2;

        require(myColateralTitle.titleValue == colateralValuePaid || colateralValuePaid >= ensuranceNeeded, "All the installments from the colateral must have been paid or at least the value paid must be greater then two times the ensureValueNeeded");

        myTitle.myTitleStatus = MyTitleWithdraw.Withdraw;

        ColateralTitles memory colateral = ColateralTitles ({
            colateralOwner: msg.sender,
            titleIdOfColateral: _idOfColateralTitle,
            contractIdOfColateral: _idOfColateralContract
        });

        colateralInfos[_titleId][_contractId] = colateral;
        
        myTitle.colateralTitleAddress = address(this);
        myColateralTitle.titleOwner = address(this);        

        emit ColateralTitleAdded(_titleId, _contractId, myTitle.drawSelected, _idOfColateralTitle, _idOfColateralContract);
    }

    function addRWAColateral(uint _idTitle, uint _contractId) public { //OK
        TitlesSold storage myTitle = titleSoldInfos[_idTitle][_contractId];

        require(myTitle.drawSelected != 0, "You haven't been selected yet!");

        require(msg.sender == myTitle.titleOwner, "Only the draw winner can create a permission!");

        bytes32 permissionHash = keccak256(abi.encodePacked(_idTitle, _contractId, myTitle.drawSelected));

        FujiPermissions memory fuji = FujiPermissions({
            idTitle: _idTitle,
            contractId: _contractId,
            drawNumber: myTitle.drawSelected
        });

        permissionInfo[permissionHash] = fuji;

        uint rwaValueNeeded = myTitle.valueOfEnsuranceNeeded;

        bytes memory permission = abi.encode(permissionHash, rwaValueNeeded, true);
    
        sender.sendMessagePayLINK(14767482510784806043, fujiReceiver,  permission); // CHAIN -14767482510784806043

        emit CreatingPermission(_idTitle, _contractId, myTitle.drawSelected, fujiReceiver);
    }

    function refundColateral(uint _idTitle, uint _contractId) public { //OK
        TitlesSold storage myTitle = titleSoldInfos[_idTitle][_contractId];
        
        require(myTitle.installmentsPaid == myTitle.installments, "All the installments must have been paid!");
        require(myTitle.paid == true, "You can't retrieve the colateral before the withdraw!");

        if(myTitle.installmentsPaid == myTitle.installments && myTitle.colateralRWAAddress != address(0)){

            bytes32 permissionHash = keccak256(abi.encodePacked(_idTitle, _contractId, myTitle.drawSelected));

            bytes memory updatePermission = abi.encode(permissionHash, myTitle.valueOfEnsuranceNeeded, false);

            sender.sendMessagePayLINK(14767482510784806043, fujiReceiver, updatePermission); // Chain - 14767482510784806043
        }else{
            if(myTitle.installmentsPaid == myTitle.installments && myTitle.colateralId != 0){
                
                ColateralTitles memory colateral = colateralInfos[_idTitle][_contractId];
                
                TitlesSold storage myColateralTitle = titleSoldInfos[colateral.titleIdOfColateral][colateral.contractIdOfColateral];

                myColateralTitle.titleOwner = colateral.colateralOwner;

                myTitle.myTitleStatus = MyTitleWithdraw.Finalized;
            }
        }
    }

    function winnerWithdraw(uint _idTitle, uint _contractId, IERC20 _stablecoin) public { //OK
        Titles storage title = allTitles[_idTitle];
        TitlesSold storage myTitle = titleSoldInfos[_idTitle][_contractId];
        
        require(msg.sender == myTitle.titleOwner || msg.sender == owner, "Msg.sender must be the contract Owner or the protocol owner!");
        require(address(_stablecoin) != address(0), "Token not allowed");
        require(myTitle.myTitleStatus == MyTitleWithdraw.Withdraw, "This title don't have the permission to withdraw");
 
        if(myTitle.installmentsPaid == myTitle.installments ||
           myTitle.colateralId != 0 || myTitle.colateralRWAAddress != address(0) && myTitle.colateralId != 0) {

            (, , bool isStable) = staff.returnAvailableStablecoin(_stablecoin);

            require(isStable == true , "Token not allowed!");

            stablecoin = _stablecoin;

            //Valida se o endereço tem o valor da parcela na carteira.
            require(stablecoin.balanceOf(address(this))>= myTitle.titleValue);
            //Transfere o valor correspondente a parcela para o contrato.
            stablecoin.transfer(myTitle.titleOwner, myTitle.titleValue);

            emit MonthlyWinnerPaid(_idTitle, myTitle.drawSelected, myTitle.titleOwner, myTitle.titleValue);
        }else{
            emit ThereAreSomePendencies(myTitle.installmentsPaid,
                                        myTitle.colateralId,
                                        myTitle.colateralTitleAddress,
                                        myTitle.colateralRWAAddress,
                                        myTitle.myTitleStatus);
        }
        myTitle.paid = true;
        title.totalValuePaid = title.totalValuePaid + myTitle.titleValue;
    }

    // Function to check titles with overdue payments and apply rules
    function verifyLatePayments(uint _titleId, uint _contractId) public { //MODIFIED
        Titles storage title = allTitles[_titleId];

        for(uint i = 1; i < title.numberOfTitlesSold; i++){

            TitlesSold storage clientTitle = titleSoldInfos[_titleId][i];
            
            uint paymentDate = staff.returnPaymentDeadline(title.paymentSchedule, title.nextDrawNumber);

            if(title.nextDrawNumber - clientTitle.installmentsPaid >= 2 || (block.timestamp - paymentDate) > 600){
                clientTitle.myTitleStatus = MyTitleWithdraw.Canceled;
                title.titleCanceled++;

                if(clientTitle.colateralId != 0 || clientTitle.colateralRWAAddress != address(0) && clientTitle.colateralId != 0){
                            
                    ColateralTitles storage colateral = colateralInfos[_titleId][_contractId];
                    Titles storage colateralTitle = allTitles[colateral.titleIdOfColateral];
                    TitlesSold storage colateralContract = titleSoldInfos[colateral.titleIdOfColateral][colateral.contractIdOfColateral];

                    colateralContract.myTitleStatus = MyTitleWithdraw.Canceled;
                    colateralTitle.titleCanceled++;
                }
            }else{
                if(block.timestamp > paymentDate) {
                    clientTitle.myTitleStatus = MyTitleWithdraw.Late;

                    emit MyTitleStatusUpdated(clientTitle.myTitleStatus);

                }
            }    
        }
    }

    function protocolWithdraw(uint _idTitle, IERC20 _tokenAddress) public onlyOwner{ //OK
        Titles storage title = allTitles[_idTitle];

        require(title.status == TitleStatus.Finalized || title.status == TitleStatus.Canceled);

        uint validTitles = title.numberOfTitlesSold - title.titleCanceled;

        uint lockedAmount = validTitles * title.titleValue;

        uint amount = title.totalValueReceived - lockedAmount;

        require(amount <= title.totalValueReceived - lockedAmount,"_amount can't exceed the title value!");

        require(address(_tokenAddress) != address(0), "Token not allowed");

        (, , bool isStable) = staff.returnAvailableStablecoin(_tokenAddress);

        require(isStable == true , "Token not allowed!");

        stablecoin = _tokenAddress;

        require(stablecoin.balanceOf(address(this))>= amount);
        stablecoin.transfer(address(staff), amount);
    }

    /* FUNÇÕES CCIP */
    //Add source chains
    function addSourceChain( uint64 _sourceChainSelector) external onlyOwner {//OK
        whitelistedSourceChains[_sourceChainSelector] = true;
    }
    //removesource chains
    function removelistSourceChain( uint64 _sourceChainSelector) external onlyOwner {//OK
        whitelistedSourceChains[_sourceChainSelector] = false;
    }
    //add senders
    function addSender(address _sender) external onlyOwner { //OK
        whitelistedSenders[_sender] = true;
    }
    //remove senders
    function removeSender(address _sender) external onlyOwner {//OK
        whitelistedSenders[_sender] = false;
    }

    function addReceiver(address _receiverAddress) public { //OK
        fujiReceiver = _receiverAddress;
    }

    /* handle a received message*/
    function _ccipReceive( Client.Any2EVMMessage memory any2EvmMessage) internal override /*onlyWhitelistedSourceChain(any2EvmMessage.sourceChainSelector) onlyWhitelistedSenders(abi.decode(any2EvmMessage.sender, (address)))*/ {
        lastReceivedMessageId = any2EvmMessage.messageId;
        lastReceivedText = abi.decode(any2EvmMessage.data, (bytes));

        bytes32 _permissionHash;
        address _colectionAddress;
        uint _nftId;

        (_permissionHash, _colectionAddress, _nftId) = abi.decode(lastReceivedText, (bytes32, address, uint));

        FujiPermissions storage permission = permissionInfo[_permissionHash];
        TitlesSold storage myTitle = titleSoldInfos[permission.idTitle][permission.contractId];

        myTitle.colateralId = _nftId;
        myTitle.colateralRWAAddress = _colectionAddress;

        if(myTitle.colateralId != 0 && myTitle.colateralRWAAddress != address(0)) {
            myTitle.myTitleStatus = MyTitleWithdraw.Withdraw;
        }

        emit MessageReceived( any2EvmMessage.messageId, any2EvmMessage.sourceChainSelector, abi.decode(any2EvmMessage.sender, (address)), abi.decode(any2EvmMessage.data, (string)));
    }

    function getLastReceivedMessageDetails() external view returns (bytes32 messageId, bytes memory text) {
        return (lastReceivedMessageId, lastReceivedText);
    }

    modifier onlyWhitelistedSourceChain(uint64 _sourceChainSelector) {
        if (!whitelistedSourceChains[_sourceChainSelector])
            revert SourceChainNotWhitelisted(_sourceChainSelector);
        _;
    }

    modifier onlyWhitelistedSenders(address _sender) {
        if (!whitelistedSenders[_sender]) revert SenderNotWhitelisted(_sender);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "The caller must be the owner!");
        _;
    }
}