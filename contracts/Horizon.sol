// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <=0.8.19;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {HorizonS} from "./HorizonS.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./HorizonStaff.sol";
import "./HorizonVRF.sol";
import "./HorizonReceipt.sol";

error SourceChainNotWhitelisted(uint64 sourceChainSelector);
error FailedToWithdrawEth(address owner, address target, uint256 value);
error SenderNotWhitelisted(address sender);

contract Horizon is CCIPReceiver, Ownable{

    using SafeMath for uint256;

    /* CCIP */
    bytes32 private lastReceivedMessageId;
    bytes private lastReceivedText;
    mapping(uint64 => bool) public whitelistedSourceChains;
    mapping(address => bool) public whitelistedSenders;

    uint titleId = 0;
    uint amountToPay;
    uint paymentDelay;
    address sepoliaReceiver;

    HorizonStaff staff = HorizonStaff(0xCd24c9696f2aA4bB15170B263E72642b5600B479); //FALTA ENDEREÇO
    IERC20 stablecoin;
    IERC721 nftToken;

    HorizonReceipt receipt = HorizonReceipt(0x0203fc68dED882C7B669b4711C42fb7A27E119a9); //FALTA ENDEREÇO
    HorizonVRF vrfv2consumer = HorizonVRF(0xE7d98f63EFCDD443549b64205B1A1d22Af8c1007); //FALTA ENDEREÇO
    HorizonS sender = HorizonS(payable(0xC3e7E776227D34874f6082f2F8476DD150DEC2de)); //FALTA ENDEREÇO

    event NewTitleCreated(uint _titleId, uint _scheduleId, uint _monthlyValue, uint _titleValue);
    event TitleStatusUpdated(TitleStatus status);
    event NewTitleSold(uint _contractId, address _owner);
    event AmountToPay(uint amountWithInterests);
    event InstallmentPaid(uint _idTitle, uint _contractId, uint _installmentsPaid);
    event EnsuranceValueNeededUpdate(uint _idTitle, uint _contractId, uint _valueOfEnsurance);
    event EnsuranceUpdated(address _temporaryEnsurance);
    event NextDraw(uint _nextDraw);
    event VRFAnswer(bool fulfilled, uint256[] randomWords, uint randomValue);
    event MonthlyWinnerSelected(uint _idTitle, uint _drawNumber, uint _randomValue, uint _selectedContractId, address _winner, uint _receiptId);
    event ColateralTitleAdded(uint _idTitle, uint _contractId, uint _drawNumber, uint _idOfColateralTitle, uint _idOfColateralContract);
    event CreatingPermission(uint _idTitle, uint _drawNumber, address _winner, address _sepoliaReceiver);
    event MonthlyWinnerPaid(uint _idTitle, uint _drawNumber, address _winner, uint _titleValue);
    event MyTitleStatusUpdated(MyTitleWithdraw myTitleStatus);
    event PaymentLateNumber(uint _i);
    event AmountLateWithInterest(uint totalAmountLate);
    event PaymentIsLate(uint lateInstallments);
    event ThereAreSomePendencies(uint _installmentsPaid, uint _colateralTitleId, address _colateralReceiptAddress, address _nftAddress, MyTitleWithdraw myTitleStatus);
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
        Withdraw //3
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
        uint drawReceiptId;
        uint colateralId;
        address colateralTitleAddress;
        address colateralNftAddress;
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

    struct EthereumPermissions{
        uint idTitle;
        uint contractId;
        uint drawNumber;
    }

    mapping(uint titleId => Titles) public allTitles; //ok
    mapping(uint titleId => mapping(uint contractId => TitlesSold)) public titleSoldInfos; //OK
    mapping(uint titleId => mapping(uint contractId => TitleRecord)) public installmentsPaidList;
    mapping(uint titleId => mapping(uint drawNumber => Draw)) public drawInfos;
    mapping(uint titleId => mapping(uint drawNumber => mapping(uint paymentOrder => TitleRecord))) public selectorVRF;
    mapping(bytes32 permissionHash => EthereumPermissions) permissionInfo;

    constructor(address _router) CCIPReceiver(_router){ //0x70499c328e1E2a3c41108bd3730F6670a44595D1
    }

    function createTitle(uint _opening, //OK
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
        monthlyInvestiment: (_value * 10 ** 18).div(_participants),
        protocolFee: (((_value * 10 ** 18).div(_participants)).mul(5)).div(100),
        numberOfTitlesSold: 0,
        totalValueReceived: 0,
        totalValuePaid: 0,
        titleCanceled: 0,
        status: TitleStatus.Waiting
        });

        allTitles[titleId] = newTitle;

        uint monthlyValue = (allTitles[titleId].monthlyInvestiment.add(allTitles[titleId].protocolFee));

        emit NewTitleCreated(titleId, scheduleId, monthlyValue, allTitles[titleId].titleValue);
    }

    function updateTitleStatus(uint _titleId) public { //OK
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
                    title.status == TitleStatus.Closed && title.nextDrawNumber.add(title.titleCanceled) > title.installments && nextDrawParticipants == 0){
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

    function buyTitle(uint64 _titleId, bool withdrawPeriod, IERC20 _tokenAddress) public { //OK
        Titles storage title = allTitles[_titleId];

        require(title.status == TitleStatus.Open,"This Title is not available. Check the Title status!");
        require(title.nextPurchaseId <= title.installments, "Title soldout!");

        title.numberOfTitlesSold++;
        //Se você deseja sacar o valor do titulo em menos de 5 meses, se sorteado. Marque como true.
        if(withdrawPeriod == true){
            uint fee = title.protocolFee;
            uint lockPeriod = 0;
        } else {
            uint fee = 0;
            uint lockPeriod = 5;
        }

        TitlesSold memory myTitle = TitlesSold({
            contractId: title.numberOfTitlesSold,
            titleValue: title.titleValue,
            installments: title.installments,
            monthlyValue: ((title.monthlyInvestiment).add(fee)),
            periodLocked: lockPeriod,
            titleOwner: msg.sender,
            installmentsPaid: 0,
            drawSelected: 0,
            colateralId: 0,
            colateralTitleAddress: address(this),
            colateralRWAAddress: address(0),
            valueOfEnsuranceNeeded: 0,
            withdrawToken: 0,
            myTitleStatus: MyTitleWithdraw.OnSchedule,
            paid: false
        });

        titleSoldInfos[_titleId][title.numberOfTitlesSold] = myTitle;

        if(title.nextPurchaseId > title.installments){
            title.status = TitleStatus.Closed;
        }

        payInstallment(_titleId, titleSoldInfos[_titleId][title.numberOfTitlesSold].contractId, titleSoldInfos[_titleId][title.numberOfTitlesSold].installmentsPaid, _tokenAddress);

        emit NewTitleSold(purchase, msg.sender);
    }

    function payInstallment(uint _idTitle, //OK
                            uint _contractId,
                            uint _installmentNumber,
                            IERC20 _tokenAddress) public {
        Titles storage title = allTitles[_idTitle];
        TitlesSold storage myTitle = titleSoldInfos[_idTitle][_contractId];
        require(title.status == TitleStatus.Closed, "Check the title status!");
        require(myTitle.installments >= _installmentNumber, "You don't have any installment left to pay!");
        require(myTitle.myTitleStatus == MyTitleWithdraw.OnSchedule || myTitle.myTitleStatus == MyTitleWithdraw.Late || myTitle.myTitleStatus == MyTitleWithdraw.Withdraw );

        uint _installment;

        if(_installmentNumber == 0){
            _installment = 1;
        } else{
            require(_installmentNumber > myTitle.installmentsPaid, "Already paid!");
            _installment = _installmentNumber;
        }

        uint paymentDate = staff.returnPaymentDeadline(title.paymentSchedule, _installment);

        if(block.timestamp > paymentDate){
            paymentDelay = (block.timestamp.sub(paymentDate));

            if(paymentDelay > 0){

                amountToPay = staff.calculateDelayedPayment(paymentDelay, amountToPay);

                emit AmountToPay(amountToPay);

                receiveInstallment(_idTitle, _contractId, amountToPay, _tokenAddress);
            }
        }else{
            amountToPay = myTitle.monthlyValue;
            
            emit AmountToPay(amountToPay);

            receiveInstallment(_idTitle, _contractId, amountToPay, _tokenAddress);
        }

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

        if(myTitle.installmentsPaid >= title.nextDrawNumber && myTitle.drawSelected == 0){
            
            staff.addParticipantsToDraw(title.paymentSchedule, title.nextDrawNumber);

            uint nextDrawParticipants = staff.returnDrawParticipants(title.paymentSchedule, title.nextDrawNumber);

            selectorVRF[_idTitle][_installmentNumber][nextDrawParticipants] = record;
        }

        bytes memory paymentReceipt = abi.encode(record);

        receiptB.mint(msg.sender, _idTitle, 1, paymentReceipt);

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

    function receiveInstallment(uint _idTitle, uint _contractId, uint _amountToPay, IERC20 _tokenAddress) internal{ //OK
        TitlesSold storage myTitle = titleSoldInfos[_idTitle][_contractId];
        Titles storage titles = allTitles[_idTitle];
        require(myTitle.contractId <= title.numberOfTitlesSold, "Enter a valid contract Id for this Title!");

        require(address(_tokenAddress) != address(0), "Enter a token address");

        (, , bool isStable) = staff.returnAvailableStablecoin(_tokenAddress);

        require(isStable == true , "Token not allowed!");

        stablecoin = _tokenAddress;

        require(_amountToPay >= myTitle.monthlyValue, "Wrong value!!");

        //Valida se o endereço tem o valor da parcela na carteira.
        require(stablecoin.balanceOf(msg.sender)>= _amountToPay, "Insufficient balance");

        //Valida se o contrato(esse), tem permissão para realizar a transferência do valor.
        require(stablecoin.allowance(msg.sender, address(this)) >= _amountToPay, "You must approve the contract to transfer the tokens");

        if(myTitle.periodLocked == 0){
            titles.totalValueReceived = titles.totalValueReceived.add(titles.monthlyInvestiment);
            
            stablecoin.transferFrom(msg.sender, address(this), titles.monthlyInvestiment);
            stablecoin.transferFrom(msg.sender, address(staff), (_amountToPay.sub(titles.monthlyInvestiment)));
        } else{
            titles.totalValueReceived = titles.totalValueReceived.add(titles.monthlyInvestiment);

            if(_amountToPay.sub(titles.monthlyInvestiment) > 0){
            
                stablecoin.transferFrom(msg.sender, address(this), titles.monthlyInvestiment);
                stablecoin.transferFrom(msg.sender, address(staff), (_amountToPay.sub(titles.monthlyInvestiment)));
            } else{
                stablecoin.transferFrom(msg.sender, address(this), _amountToPay);
            }
        }

        myTitle.installmentsPaid++;
    }

    function updateValueOfEnsurance(uint _idTitle, uint _contractId) internal { //OK
        Titles storage titles = allTitles[_idTitle];
        TitlesSold storage myTitle = titleSoldInfos[_idTitle][_contractId];

        uint valueAlreadyPaid = ((myTitle.installmentsPaid).mul(titles.monthlyInvestiment));

        if(valueAlreadyPaid >= myTitle.titleValue){
            myTitle.valueOfEnsuranceNeeded = 0;
        }else{
            myTitle.valueOfEnsuranceNeeded = (myTitle.titleValue).sub(valueAlreadyPaid);
        }

        emit EnsuranceValueNeededUpdate(_idTitle, _contractId, myTitle.valueOfEnsuranceNeeded);
    }

    function monthlyVRFWinner(uint _idTitle) public { //OK
        Titles storage title = allTitles[_idTitle];

        uint thisDrawDate = staff.returnDrawDate(title.paymentSchedule, title.nextDrawNumber);

        require(block.timestamp > thisDrawDate, "Isn't the time yet!");

        uint nextDrawParticipants = staff.returnDrawParticipants(title.paymentSchedule, title.nextDrawNumber);

        uint256 requestId = vrfv2consumer.requestRandomWords(_idTitle, title.nextDrawNumber, nextDrawParticipants);

        title.status = TitleStatus.Waiting;

        Draw memory draw = Draw({
            idTitle: _idTitle,
            drawNumber: title.nextDrawNumber,
            drawDate: block.timestamp,
            totalParticipants: title.nextDrawTitlesAvailable,
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

    function receiveVRFRandomNumber(uint256 _idTitle) public{ //OK
        Titles storage title = allTitles[_idTitle];
        Draw storage draw = drawInfos[_idTitle][title.nextDrawNumber];

        (bool fulfilled, uint256[] memory randomWords, uint256 randomValue) = vrfv2consumer.getRequestStatus(draw.requestId);

        require(fulfilled, "VRF request not fulfilled");
        
        emit VRFAnswer(fulfilled, randomWords, randomValue);

        TitleRecord storage winningTicket = selectorVRF[_idTitle][drawInfos.drawNumber][randomValue];

        draw.randomNumberVRF = randomValue;
        draw.selectedContractID = winningTicket.contractId;
        draw.winner = winningTicket.user;

        //Emite o comprovante do sorteio.
        bytes memory drawResult = abi.encode(draw);
        uint receiptId = receipt.safeMint(winningTicket.user, string(drawResult));

        TitlesSold storage myTitle = titleSoldInfos[_idTitle][winningTicket.contractId];

        myTitle.drawSelected = draw.drawNumber;
        myTitle.drawReceiptId = receiptId;
        updateValueOfEnsurance(_idTitle, winningTicket.contractId);

        title.nextDrawNumber++;

        emit MonthlyWinnerSelected(_idTitle, drawInfos.drawNumber, randomValue, winningTicket.contractId, winningTicket.user, receiptId);        
    }

    function addTitleColateral(uint _titleId, uint _contractId, uint _idOfColateralTitle, uint _idOfColateralContract, uint _tokenId) public{ //OK
        require(msg.sender == ERC721(receipt).ownerOf(_tokenId), "The winner must have the receipt token to add the colateralTitle");

        TitlesSold storage myColateralTitle = titleSoldInfos[_idOfColateralTitle][_idOfColateralContract];

        require(myColateralTitle.drawReceiptId == _tokenId, "The token Id must correspond to the receipt of your colateral Title!");

        uint colateralValue = myColateralTitle.installmentsPaid.mul(myColateralTitle.monthlyValue);
        
        TitlesSold storage myTitle = titleSoldInfos[_titleId][_contractId];

        uint targetValue = (myTitle.titleValue).sub((myTitle.installmentsPaid).mul(myTitle.monthlyValue));

        require(colateralValue >= targetValue, "The colateral must have a bigger value than the targetValue");

        myTitle.colateralId = _tokenId;
        myTitle.colateralTitleAddress = address(receipt);
        myTitle.myTitleStatus = MyTitleWithdraw.Withdraw;

        nftToken = receipt;

        nftToken.transferFrom(msg.sender, address(this), _tokenId);

        emit ColateralTitleAdded(_titleId, _contractId, myTitle.drawSelected, _idOfColateralTitle, _idOfColateralContract);
    }

    function addNFTColateral(uint _idTitle, uint _contractId, uint _drawNumber) public { //OK
        TitlesSold storage myTitle = titleSoldInfos[_idTitle][_contractId];
        Draw storage draw = drawInfos[_idTitle][_drawNumber];

        require(myTitle.drawSelected == _drawNumber, "The token Id must correspond to the receipt of your colateral Title!");
        require(msg.sender == draw.winner, "Only the draw winner can create a permission!");

        bytes32 permissionHash = keccak256(abi.encodePacked(_idTitle, _contractId, _drawNumber));

        EthereumPermissions memory ethereum = EthereumPermissions({
            idTitle: _idTitle,
            contractId: _contractId,
            drawNumber: _drawNumber
        });

        permissionInfo[permissionHash] = ethereum;

        bytes memory permission = abi.encode(permissionHash, myTitle.valueOfEnsuranceNeeded, true);
    
        sender.sendMessagePayLINK(16015286601757825753, /*_receiver*/ sepoliaReceiver,  permission);

        emit CreatingPermission(_idTitle, _drawNumber, draw.winner, sepoliaReceiver);
    }

    function refundColateral(uint _idTitle, uint _contractId, uint _drawNumber) public { //OK
        TitlesSold storage myTitle = titleSoldInfos[_idTitle][_contractId];
        if(myTitle.installmentsPaid == myTitle.installments && myTitle.colateralNftAddress != address(0)){

            bytes32 permissionHash = keccak256(abi.encodePacked(_idTitle, _contractId, _drawNumber));

            bytes memory updatePermission = abi.encode(permissionHash, myTitle.valueOfEnsuranceNeeded, false);

            sender.sendMessagePayLINK(16015286601757825753, /*_receiver*/ sepoliaReceiver, updatePermission);
        }else{
            if(myTitle.installmentsPaid == myTitle.installments && myTitle.colateralTitleAddress != address(0)){
                require(myTitle.installmentsPaid == myTitle.installments, "All the installments must have been paid!");

                nftToken = receipt;

                nftToken.safeTransferFrom(address(this), myTitle.titleOwner, myTitle.drawReceiptId);

                myTitle.myTitleStatus = MyTitleWithdraw.Withdraw;
            }
        }
    }

    function winnerWithdraw(uint _idTitle, uint _drawNumber, IERC20 _stablecoin) public { //OK
        Titles storage title = allTitles[_idTitle];
        Draw storage draw = drawInfos[_idTitle][_drawNumber];
        TitlesSold storage myTitle = titleSoldInfos[_idTitle][draw.selectedContractID];

        address protocolOwner = owner();
        
        require(msg.sender == myTitle.titleOwner || msg.sender == protocolOwner, "Msg.sender must be the contract Owner or the protocol owner!");
        require(address(_stablecoin) != address(0), "Token not allowed");
        require(myTitle.myTitleStatus == MyTitleWithdraw.Withdraw, "This title don't have the permission to withdraw");
 
        if(myTitle.installmentsPaid == myTitle.installments ||
           myTitle.colateralTitleAddress != address(0) || myTitle.colateralNftAddress != address(0)) {

            (, , bool isStable) = staff.returnAvailableStablecoin(_stablecoin);

            require(isStable == true , "Token not allowed!");

            stablecoin = _stablecoin;

            //Valida se o endereço tem o valor da parcela na carteira.
            require(stablecoin.balanceOf(address(this))>= myTitle.titleValue);
            //Valida se a carteira vencedora possui os tokens/recibos.
            require(draw.winner == receipt.ownerOf(draw.receiptId), "The winner should have the draw receipt to receive the payment!");
            //Transfere o valor correspondente a parcela para o contrato.
            stablecoin.transfer(draw.winner, myTitle.titleValue);

            emit MonthlyWinnerPaid(_idTitle, _drawNumber, draw.winner, myTitle.titleValue);
        }else{
            emit ThereAreSomePendencies(myTitle.installmentsPaid,
                                        myTitle.colateralId,
                                        myTitle.colateralTitleAddress,
                                        myTitle.colateralNftAddress,
                                        myTitle.myTitleStatus);
        }
        myTitle.paid = true;
        title.totalValuePaid = title.totalValuePaid.add(myTitle.titleValue);
    }

    // Function to check titles with overdue payments and apply rules
    function verifyLatePayments(uint _titleId, uint _contractId) public { //OK
        Titles storage title = allTitles[_titleId];
        TitlesSold storage clientTitle = titleSoldInfos[_titleId][_contractId];

        if(title.nextDrawNumber > 1 && clientTitle.installmentsPaid == 0){
            clientTitle.myTitleStatus = MyTitleWithdraw.Canceled;
            title.titleCanceled++;
        }else{
            uint dateOfFirstLatePayment = staff.returnPaymentDeadline(title.paymentSchedule, clientTitle.installmentsPaid.add(1));

            if(block.timestamp.sub(dateOfFirstLatePayment) > 0){

                clientTitle.myTitleStatus = MyTitleWithdraw.Late;

                emit MyTitleStatusUpdated(clientTitle.myTitleStatus);

                uint totalAmountOfInterest = 0;

                uint mostRecentDraw = title.nextDrawNumber.sub(1);

                for(uint i = clientTitle.installmentsPaid; i <= mostRecentDraw; i++) {

                    emit PaymentLateNumber(i);

                    uint paymentDate = staff.returnPaymentDeadline(title.paymentSchedule, i);
                    uint paymentTimeLate = block.timestamp.sub(paymentDate);
                    uint inicialAmountToPay = clientTitle.monthlyValue;
                    totalAmountOfInterest = (staff.calculateDelayedPayment(paymentTimeLate, inicialAmountToPay)).sub(clientTitle.monthlyValue);

                    emit AmountLateWithInterest(totalAmountOfInterest);
                }

                uint amountAlreadyPaid = clientTitle.monthlyValue.mul(clientTitle.installmentsPaid);

                if (totalAmountOfInterest > amountAlreadyPaid.div(2) && clientTitle.myTitleStatus == MyTitleWithdraw.Late){
                            
                    clientTitle.myTitleStatus = MyTitleWithdraw.Canceled;
                    title.titleCanceled++;
                    
                }
            }
        } 
    }

    function titleClosedWithdraw(uint _idTitle, IERC20 _tokenAddress) public onlyOwner{ //OK
        Titles storage title = allTitles[_idTitle];

        uint amount = title.totalValueReceived.sub(title.totalValuePaid);

        require(amount <= title.totalValueReceived.sub(title.totalValuePaid),"_amount can't exceed the title value!");

        require(address(_tokenAddress) != address(0), "Token not allowed");

        (, , bool isStable) = staff.returnAvailableStablecoin(_tokenAddress);

        require(isStable == true , "Token not allowed!");

        stablecoin = _tokenAddress;

        //Valida se o endereço tem o valor da parcela na carteira.
        require(stablecoin.balanceOf(address(this))>= amount);
        //Transfere o valor correspondente a parcela para o contrato.
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
        sepoliaReceiver = _receiverAddress;
    }

    /* handle a received message*/
    function _ccipReceive( Client.Any2EVMMessage memory any2EvmMessage) internal override /*onlyWhitelistedSourceChain(any2EvmMessage.sourceChainSelector) onlyWhitelistedSenders(abi.decode(any2EvmMessage.sender, (address)))*/ {
        lastReceivedMessageId = any2EvmMessage.messageId;
        lastReceivedText = abi.decode(any2EvmMessage.data, (bytes));

        bytes32 _permissionHash;
        address _colectionAddress;
        uint _nftId;

        (_permissionHash, _colectionAddress, _nftId) = abi.decode(lastReceivedText, (bytes32, address, uint));

        EthereumPermissions storage permission = permissionInfo[_permissionHash];
        TitlesSold storage myTitle = titleSoldInfos[permission.idTitle][permission.contractId];

        myTitle.colateralId = _nftId;
        myTitle.colateralNftAddress = _colectionAddress;

        if(myTitle.colateralId != 0 && myTitle.colateralNftAddress != address(0)) {
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
}