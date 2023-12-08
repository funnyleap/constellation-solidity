// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <=0.8.20;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {HorizonS} from "./HorizonS.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./HorizonStaff.sol";
import "./HorizonVRF.sol";

error ThereIsNoTitlesAvailableAnymore(uint numberOfTitlesSold);
error SourceChainNotWhitelisted(uint64 sourceChainSelector);
error FailedToWithdrawalEth(address owner, address target, uint256 value);
error SenderNotWhitelisted(address sender);

/**
 * @title Horizon Financial Products
 * @author Barba
 * @notice This contract is the foundation of the protocol structure. Consortium Titles are created, sold, and their prizes are paid through it.
 * @dev This contract integrates with Chainlink CCIP and VRF.
 */
contract Horizon is CCIPReceiver, OwnerIsCreator{

    /// CCIP VARIABLES AND STORAGES
    bytes32 private lastReceivedMessageId;
    bytes private lastReceivedText;
    mapping(uint64 => bool) public whitelistedSourceChains;
    mapping(address => bool) public whitelistedSenders;

    /// EVENTS
    
    /// @notice Event emitted when a new Title is created!
    event NewTitleCreated(uint _titleId, uint _scheduleId, uint _titleValue, uint _installments, uint _monthlyValue);
    /// @notice Event emitted when the Title's status changes.
    event TitleStatusUpdated(TitleStatus _status);
    /// @notice Event emitted when a share of the Title is sold.
    event NewTitleSold(uint _titleId, uint _contractId, address _owner);
    /// @notice Event emitted when the value changes due to late interest.
    event AmountToPay(uint _amountWithInterests);
    /// @notice Event emitted when an installment is paid.
    event InstallmentPaid(uint _idTitle, uint _contractId, uint _amount, uint _installmentsPaid);
    /// @notice Event emitted when an installment is paid and the value of the necessary insurance for withdrawal is reduced.
    event InsuranceValueNeededUpdate(uint _idTitle, uint _contractId, uint _valueOfInsurance);
    /// @notice Event emitted when collateral is allocated and the owner's address changes.
    event InsuranceUpdated(address _temporaryInsurance);
    /// @notice Event emitted when a draw starts.
    event DrawHasStarted(uint _titleId, uint _nextDrawNumber, uint _nextDrawParticipants);
    /// @notice Event emitted when the VRF returns the drawn number.
    event VRFAnswer(bool _fulfilled, uint256[] _randomWords, uint _randomValue);
    /// @notice Event emitted when the winner is revealed.
    event MonthlyWinnerSelected(uint _idTitle, uint _drawNumber, uint _randomValue, uint _selectedContractId, address _winner);
    /// @notice Event emitted when a Consórcio Quota is added as Collateral in another Title.
    event CollateralTitleAdded(uint _idTitle, uint _contractId, uint _drawNumber, uint _idOfCollateralTitle, uint _idOfCollateralContract);
    /// @notice Event emitted when sending permission to allocate RWA to another network.
    event CreatingPermission(uint _idTitle, uint _contractId, uint _drawSelected, address _fujiReceiver);
    /// @notice Event emitted when the drawn winner withdrawals the Consórcio amount.
    event MonthlyWinnerPaid(uint _idTitle, uint _drawNumber, address _winner, uint _titleValue);
    /// @notice Event emitted when the status of a Consórcio Quota is updated.
    event MyTitleStatusUpdated(MyTitleWithdrawal _myTitleStatus);
    /// @notice Event emitted to report the number of late payments.
    event PaymentLateNumber(uint _i);
    /// @notice Event emitted to report the updated amount with late interest. 
    event AmountLateWithInterest(uint _totalAmountLate);
    /// @notice Event emitted to inform the owner of the Consórcio Letter that has late payments.
    event PaymentIsLate(uint _lateInstallments);
    /// @notice Event emitted when the allocated Collateral is returned to the owner.
    event CollateralRefunded(uint _idTitle, uint _contractId, uint _collateralId);
    /// @notice Event emitted when the owner of the Consórcio Quota tries to withdrawals, but the Quota has pending issues.
    event ThereAreSomePendencies(uint _installmentsPaid, uint _collateralTitleId, address _collateralTitleAddress, address _collateralRWAAddress, MyTitleWithdrawal _myTitleStatus);
    /// @notice Event emitted to report the last installment paid.
    event LastInstallmentPaid(uint _installmentsPaid);
    /// @notice Event emitted when a Consórcio Quota is canceled due to delay.
    event ThisTitleHasBeenCanceled(uint _titlesAvailableForNextDraw);
    /// @notice Event emitted when a Consórcio is canceled.
    event TitleCanceled(uint _titleId, uint _contractId, uint _lastInstallmentPaid);
    /// @notice Event emitted when the CCIP receives a message.
    event MessageReceived( bytes32 indexed _messageId, uint64 indexed _sourceChainSelector, address _sender, string _text);

    /// COMMON STATE VARIABLES
    uint titleId = 0;
    address fujiReceiver;

    /// ENUMS

    ///@notice Enum for the overall status of the Title
    enum TitleStatus{
        Canceled, //0
        Closed, //1
        Finalized, //2
        Open, //3
        Waiting //4
    }

    TitleStatus status;
    
    ///@notice Enum for the Status of the Consórcio Quotas
    enum MyTitleWithdrawal{
        Canceled, //0
        Late, //1
        OnSchedule, //2
        Withdrawal, //3
        Finalized //4
    }
    
    MyTitleWithdrawal myTitleStatus;

    /// STRUCTS
    
    ///@notice Consórcio Title Structure
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

    ///@notice Structure of the Purchased Share of the Consórcio Title
    struct TitlesSold {
        uint contractId;
        uint schedule;
        uint titleValue;
        uint installments;
        uint monthlyValue;
        uint periodLocked;
        address titleOwner;
        uint installmentsPaid;
        uint drawSelected;
        uint collateralId;
        address collateralTitleAddress;
        address collateralRWAAddress;
        uint valueOfInsuranceNeeded;
        MyTitleWithdrawal myTitleStatus;
        bool paid;
    }
    ///@notice Payment Structure
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
    ///@notice Draw Structure
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
    ///@notice Structure for Allocating Titles as Collateral
    struct CollateralTitles {
        address collateralOwner;
        uint titleIdOfCollateral;
        uint contractIdOfCollateral;
    }
    ///@notice Structure for Creating RWA Allocation Permissions
    struct FujiPermissions{
        uint idTitle;
        uint contractId;
        uint drawNumber;
    }

    /// MAPPINGS

    ///@notice storage for all created Contracts
    mapping(uint titleId => Titles) public allTitles;
    ///@notice storage for the Consórcio Quotas
    mapping(uint titleId => mapping(uint contractId => TitlesSold)) public titleSoldInfos;
    ///@notice storage for draw information
    mapping(uint titleId => mapping(uint drawNumber => Draw)) public drawInfos;
    ///@notice storage for winner selection
    mapping(uint titleId => mapping(uint drawNumber => mapping(uint paymentOrderOrRandomValue => TitleRecord))) public selectorVRF;
    ///@notice storage for RWA allocation permissions
    mapping(bytes32 permissionHash => FujiPermissions) public permissionInfo;
    ///@notice storage for Title Quotas used as collateral
    mapping(uint titleId => mapping(uint contractId => CollateralTitles)) public collateralInfos;
    
    /// Instantiation of Dependencies
    IERC20 stablecoin;
    IERC721 nftToken;
    HorizonStaff staff = HorizonStaff(0x3547951AAA367094AFABcaE24f123473fF502bFa);
    HorizonVRF vrfv2consumer = HorizonVRF(0xA75447C1A6dD04dA5cEB791023fa7192cc577CFa);
    HorizonS sender = HorizonS(payable(0xdED9E0F0D9274A74CC5506f80802781dDe6b7E11));

    constructor(address _router) CCIPReceiver(_router){
    }

    /**
     * 
     * @param _opening the time when the sale of shares should start
     * @param _closing the time when the sale of shares should end, if all the Quotas have not been sold.
     * @param _participants the maximum number of Quotas to be sold for this Consórcio Title
     * @param _value total value of the Consórcio Quota.
     * @notice _value is divided by _participants and from this, we have the monthly value of the Consórcio Title.
     */
    function createTitle(uint _opening,
                         uint _closing,
                         uint _participants,
                         uint _value) public  onlyOwner {
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
        protocolFee: (((_value * 10 ** 18) / _participants) * 10) / 100,
        numberOfTitlesSold: 0,
        totalValueReceived: 0,
        totalValuePaid: 0,
        titleCanceled: 0,
        status: TitleStatus.Waiting
        });

        allTitles[titleId] = newTitle;

        uint monthlyValue = (allTitles[titleId].monthlyInvestiment + (allTitles[titleId].protocolFee));

        emit NewTitleCreated(titleId, scheduleId, allTitles[titleId].titleValue, _participants, monthlyValue );
    }
    
    /**
     * 
     * @param _titleId Identifier of the Consórcio Title that should be updated
     * @notice if the Title does not meet the established parameters, nothing will occur.
     */
    function updateTitleStatus(uint _titleId) public onlyOwner {
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

    /**
     * 
     * @param _titleId Identifier of the Consórcio Title for which the client wishes to purchase a Quota
     * @param withdrawalPeriod withdrawal modality that the client desires
     * @param _tokenAddress the stablecoin that will be used for payment.
     * @dev on the mainnet, the stablecoin will be dynamic.
     */
    function buyTitle(uint64 _titleId, bool withdrawalPeriod, IERC20 _tokenAddress) public {
        Titles storage title = allTitles[_titleId];

        require(title.status == TitleStatus.Open,"This Title is not available. Check the Title status!");
        require(title.numberOfTitlesSold <= title.installments, "Title soldout!");

        title.numberOfTitlesSold++;

        uint fee;
        uint lockPeriod;
        if(withdrawalPeriod == true){
            fee = title.protocolFee;
            lockPeriod = 0;
        } else {
            fee = (title.protocolFee / 2);
            lockPeriod = ((title.installments / 2) + 1);
        }

        TitlesSold memory myTitle = TitlesSold({
            contractId: title.numberOfTitlesSold,
            schedule: title.paymentSchedule,
            titleValue: title.titleValue,
            installments: title.installments,
            monthlyValue: ((title.monthlyInvestiment) + (fee)),
            periodLocked: lockPeriod,
            titleOwner: msg.sender,
            installmentsPaid: 0,
            drawSelected: 0,
            collateralId: 0,
            collateralTitleAddress: address(0),
            collateralRWAAddress: address(0),
            valueOfInsuranceNeeded: 0,
            myTitleStatus: MyTitleWithdrawal.OnSchedule,
            paid: false
        });

        titleSoldInfos[_titleId][title.numberOfTitlesSold] = myTitle;

        payInstallment(_titleId, title.numberOfTitlesSold, _tokenAddress);

        emit NewTitleSold(_titleId, title.numberOfTitlesSold, msg.sender);
    }

    /**
     * @notice This function is responsible for receiving payment information, checking for delays, and processing Interest.
     * @param _idTitle Identifier of the Consortium Title for which the client wishes to pay the installment
     * @param _contractId Identifier of the Consortium Quota for which the client wishes to pay the installment
     * @param _tokenAddress the stablecoin that will be used for payment.
     * @dev on the mainnet, the stablecoin will be dynamic.
     */
    function payInstallment(uint _idTitle,
                            uint _contractId,
                            IERC20 _tokenAddress) public {
        Titles storage title = allTitles[_idTitle];
        TitlesSold storage myTitle = titleSoldInfos[_idTitle][_contractId];
        require(title.status == TitleStatus.Closed || title.status == TitleStatus.Open, "Check the title status!");
        require(myTitle.myTitleStatus == MyTitleWithdrawal.OnSchedule || myTitle.myTitleStatus == MyTitleWithdrawal.Late || myTitle.myTitleStatus == MyTitleWithdrawal.Withdrawal );
        require(myTitle.installmentsPaid < title.installments, "You already paid all the installments!");

        uint _installment;
        uint paymentDelay;

        if(myTitle.installmentsPaid > 0 ){
            _installment = (myTitle.installmentsPaid + 1);
        } else {
            _installment = 1;
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

        if(myTitle.installmentsPaid >= title.nextDrawNumber && myTitle.drawSelected == 0 || title.nextDrawNumber == 1 && myTitle.installmentsPaid == 0 && myTitle.drawSelected == 0){

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

            staff.addParticipantsToDraw(title.paymentSchedule, title.nextDrawNumber);

            uint nextDrawParticipants = staff.returnDrawParticipants(title.paymentSchedule, title.nextDrawNumber);

            selectorVRF[_idTitle][_installment][nextDrawParticipants] = record;
        }

        if(myTitle.installmentsPaid == myTitle.installments){
            myTitle.myTitleStatus = MyTitleWithdrawal.Withdrawal;

            if(myTitle.collateralId != 0 ){
                refundCollateral(_idTitle, _contractId);
            }
        }
        if(myTitle.installmentsPaid == title.nextDrawNumber &&  myTitle.myTitleStatus == MyTitleWithdrawal.Late){
            myTitle.myTitleStatus = MyTitleWithdrawal.OnSchedule;
        }

        updateValueOfInsurance(_idTitle, _contractId);

        emit InstallmentPaid(_idTitle, _contractId, amountToPay, myTitle.installmentsPaid);
    }

    /**
     * @notice This function is internal and will be called by the payInstallment function to process the payment.
     * @param _idTitle Identifier of the Consortium Title for which the client wishes to pay the installment
     * @param _contractId Identifier of the Consortium Quota for which the client wishes to pay the installment
     * @param _amountToPay is the amount to be paid, with or without the incidence of interest.
     * @param _tokenAddress the stablecoin that will be used for payment.
     * @dev on the mainnet, the stablecoin will be dynamic.
     */
    function receiveInstallment(uint _idTitle, uint _contractId, uint _amountToPay, IERC20 _tokenAddress) internal{
        TitlesSold storage myTitle = titleSoldInfos[_idTitle][_contractId];
        Titles storage title = allTitles[_idTitle];
        require(myTitle.contractId <= title.numberOfTitlesSold, "Enter a valid contract Id for this Title!");
        require(myTitle.myTitleStatus != MyTitleWithdrawal.Canceled || myTitle.myTitleStatus != MyTitleWithdrawal.Finalized, "your title already have been finalized or canceled. Please check the status.");
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

    /**
     * @notice This function is internal and will be called by the payInstallment function to update the value of the necessary insurance.
     * @param _idTitle Identifier of the Consortium Title for which the client wishes to pay the installment
     * @param _contractId Identifier of the Consortium Quota for which the client wishes to pay the installment
     */
    function updateValueOfInsurance(uint _idTitle, uint _contractId) internal {
        Titles storage titles = allTitles[_idTitle];
        TitlesSold storage myTitle = titleSoldInfos[_idTitle][_contractId];

        uint valueAlreadyPaid = (myTitle.installmentsPaid * titles.monthlyInvestiment);

        if(valueAlreadyPaid >= myTitle.titleValue){
            myTitle.valueOfInsuranceNeeded = 0;
        }else{
            myTitle.valueOfInsuranceNeeded = myTitle.titleValue - valueAlreadyPaid;
        }

        emit InsuranceValueNeededUpdate(_idTitle, _contractId, myTitle.valueOfInsuranceNeeded);
    }

    /**
     * @notice this function sends the request for a random number to the vrfv2consumer contract so that the draw can be carried out
     * @param _idTitle Identifier of the Consortium Title that will be drawn
     */
    function monthlyVRFWinner(uint _idTitle) public  onlyOwner {
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

        emit DrawHasStarted(_idTitle, title.nextDrawNumber, nextDrawParticipants);
    }

    /**
     * @notice this function processes the drawn number with the selectorVRF mapping to reveal the winner
     * @param _idTitle Identifier of the Consortium Title that will have the winner revealed
     */
    function receiveVRFRandomNumber(uint256 _idTitle) public {
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

        updateValueOfInsurance(_idTitle, winningTicket.contractId);

        title.status = TitleStatus.Closed;

        title.nextDrawNumber++;

        emit MonthlyWinnerSelected(_idTitle, draw.drawNumber, randomValue, winningTicket.contractId, winningTicket.user);
    }

    /**
     * @notice This function is responsible for checking values, status, and adding Consortium Title Quotas as collateral.
     * @param _titleId The ID of the Consortium Title in which the Collateral will be allocated.
     * @param _contractId The ID of the Consortium Quota where the Collateral will be allocated.
     * @param _idOfCollateralTitle The ID of the Consortium Title that will be used as Collateral.
     * @param _idOfCollateralContract The ID of the Consortium Quota that will be used as Collateral.
     */
    function addTitleAsCollateral(uint _titleId, uint _contractId, uint _idOfCollateralTitle, uint _idOfCollateralContract) public{
        TitlesSold storage myCollateralTitle = titleSoldInfos[_idOfCollateralTitle][_idOfCollateralContract];
        TitlesSold storage myTitle = titleSoldInfos[_titleId][_contractId]; 

        require(myTitle.drawSelected != 0, "You haven't been selected yet!");
        require(myTitle.titleOwner == msg.sender, "Only the owner can add a collateral!");
        require(myCollateralTitle.titleOwner == msg.sender, "Only the owner can add a collateral!");
        require(myCollateralTitle.titleValue >= myTitle.valueOfInsuranceNeeded, "The collateral total value must be greater than tue insuranceValueNeeded");
        
        uint colateralValuePaid = myCollateralTitle.installmentsPaid * myCollateralTitle.monthlyValue;
        uint insuranceNeeded = myTitle.valueOfInsuranceNeeded * 2;

        require(myCollateralTitle.titleValue == colateralValuePaid || colateralValuePaid >= insuranceNeeded, "All the installments from the colateral must have been paid or at least the value paid must be greater then two times the ensureValueNeeded");

        myTitle.myTitleStatus = MyTitleWithdrawal.Withdrawal;

        CollateralTitles memory collateral = CollateralTitles ({
            collateralOwner: msg.sender,
            titleIdOfCollateral: _idOfCollateralTitle,
            contractIdOfCollateral: _idOfCollateralContract
        });

        collateralInfos[_titleId][_contractId] = collateral;
        
        myTitle.collateralTitleAddress = address(this);
        myTitle.collateralId = myCollateralTitle.contractId;
        myCollateralTitle.titleOwner = address(this);

        emit CollateralTitleAdded(_titleId, _contractId, myTitle.drawSelected, _idOfCollateralTitle, _idOfCollateralContract);
    }

    /**
     * @notice This function is responsible for creating the RWA allocation permission and sending it through the CCIP.
     * @param _idTitle The ID of the Consortium Title in which the Collateral will be allocated.
     * @param _contractId The ID of the Consortium Quota where the Collateral will be allocated.
     */
    function addRWACollateral(uint _idTitle, uint _contractId) public {
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

        uint rwaValueNeeded = myTitle.valueOfInsuranceNeeded;

        bytes memory permission = abi.encode(permissionHash, rwaValueNeeded, true);
    
        sender.sendMessagePayLINK(14767482510784806043, fujiReceiver,  permission);

        emit CreatingPermission(_idTitle, _contractId, myTitle.drawSelected, fujiReceiver);
    }

    /**
     * @notice this function is responsible for the return of the collateral, whether it is RWA or Title, and is called internally.
     * @param _idTitle The ID of the Consortium Title that the client holds the Quota of.
     * @param _contractId The ID of the Consortium Quota that has been fully paid and will receive the return of the Collateral.
     */
    function refundCollateral(uint _idTitle, uint _contractId) internal {
        TitlesSold storage myTitle = titleSoldInfos[_idTitle][_contractId];
        
        require(myTitle.installmentsPaid == myTitle.installments, "All the installments must have been paid!");
        require(myTitle.paid == true, "You can't retrieve the collateral before the withdrawal!");

        if(myTitle.installmentsPaid == myTitle.installments && myTitle.collateralRWAAddress != address(0)){

            bytes32 permissionHash = keccak256(abi.encodePacked(_idTitle, _contractId, myTitle.drawSelected));

            bytes memory updatePermission = abi.encode(permissionHash, myTitle.valueOfInsuranceNeeded, false);

            myTitle.myTitleStatus = MyTitleWithdrawal.Finalized;

            sender.sendMessagePayLINK(14767482510784806043, fujiReceiver, updatePermission); // Chain - 14767482510784806043

            emit CollateralRefunded(_idTitle, _contractId, myTitle.collateralId);
        }else{
            if(myTitle.installmentsPaid == myTitle.installments && myTitle.collateralId != 0){
                
                CollateralTitles memory collateral = collateralInfos[_idTitle][_contractId];
                
                TitlesSold storage myCollateralTitle = titleSoldInfos[collateral.titleIdOfCollateral][collateral.contractIdOfCollateral];

                myCollateralTitle.titleOwner = collateral.collateralOwner;

                myTitle.myTitleStatus = MyTitleWithdrawal.Finalized;

                emit CollateralRefunded(_idTitle, _contractId, myTitle.collateralId);
            }
        }
    }

    /**
     * @notice This function is responsible for paying the total value of the Quota to clients.
     * @param _idTitle The ID of the Consortium Title that the client holds the Quota of.
     * @param _contractId The ID of the Consortium Quota that has been paid off or received collateral for withdrawal release.
     * @param _stablecoin The address of the currency that will be used to pay the winner.
     * @dev on the mainnet, the stablecoin will be dynamic.
     */
    function winnerWithdrawal(uint _idTitle, uint _contractId, IERC20 _stablecoin) public {
        Titles storage title = allTitles[_idTitle];
        TitlesSold storage myTitle = titleSoldInfos[_idTitle][_contractId];
        
        require(msg.sender == myTitle.titleOwner || msg.sender == owner(), "Msg.sender must be the contract Owner or the protocol owner!");
        require(address(_stablecoin) != address(0), "Token not allowed");
        require(myTitle.myTitleStatus == MyTitleWithdrawal.Withdrawal, "This title don't have the permission to withdrawal");

        if(myTitle.periodLocked > 0){
            require(title.nextDrawNumber > myTitle.periodLocked, "You can't withdrawal at this time. Your lock period ends on the 6 month!");
        }
 
        if(myTitle.installmentsPaid == myTitle.installments ||
           myTitle.collateralId != 0 || myTitle.collateralRWAAddress != address(0) && myTitle.collateralId != 0) {

            (, , bool isStable) = staff.returnAvailableStablecoin(_stablecoin);

            require(isStable == true , "Token not allowed!");

            stablecoin = _stablecoin;

            require(stablecoin.balanceOf(address(this))>= myTitle.titleValue);

            stablecoin.transfer(myTitle.titleOwner, myTitle.titleValue);

            emit MonthlyWinnerPaid(_idTitle, myTitle.drawSelected, myTitle.titleOwner, myTitle.titleValue);
        }else{
            emit ThereAreSomePendencies(myTitle.installmentsPaid,
                                        myTitle.collateralId,
                                        myTitle.collateralTitleAddress,
                                        myTitle.collateralRWAAddress,
                                        myTitle.myTitleStatus);
        }
        myTitle.paid = true;
        title.totalValuePaid = title.totalValuePaid + myTitle.titleValue;
    }

    /**
     * @notice This function is responsible for verifying late payments
     * @param _titleId The ID of the Consortium Title that the client holds the Quota of.
     * @param _contractId The ID of the Consortium Quota that is overdue.
     */
    function verifyLatePayments(uint _titleId, uint _contractId) public { 
        Titles storage title = allTitles[_titleId];
        TitlesSold storage clientTitle = titleSoldInfos[_titleId][_contractId];
        
        uint lastInstallmentPaid = clientTitle.installmentsPaid;

        uint delayedPaymentDate = staff.returnPaymentDeadline(title.paymentSchedule, (lastInstallmentPaid + 1));
        uint cancellationLimit = 600;

        if((block.timestamp - delayedPaymentDate) > cancellationLimit ){
            clientTitle.myTitleStatus = MyTitleWithdrawal.Canceled;
            title.titleCanceled++;

            emit TitleCanceled(_titleId, _contractId, lastInstallmentPaid);
            
            if(clientTitle.collateralTitleAddress != address(0) || clientTitle.collateralRWAAddress != address(0)){
                            
                CollateralTitles storage collateral = collateralInfos[_titleId][_contractId];

                Titles storage collateralTitle = allTitles[collateral.titleIdOfCollateral];

                TitlesSold storage collateralContract = titleSoldInfos[collateral.titleIdOfCollateral][collateral.contractIdOfCollateral];

                collateralTitle.titleCanceled++;
                collateralContract.myTitleStatus = MyTitleWithdrawal.Canceled;
            }
        }else{
            if(block.timestamp > delayedPaymentDate && (block.timestamp - delayedPaymentDate) < cancellationLimit) {

                clientTitle.myTitleStatus = MyTitleWithdrawal.Late;
                emit MyTitleStatusUpdated(clientTitle.myTitleStatus);

            }
        }    
        
    }

    /**
     * @notice This function is responsible for the withdrawal of potential cancellation penalties.
     * @notice Nothing can be withdrawn until the Title has been finalized or closed.
     * @param _idTitle The ID of the Consortium Title that the client holds the Quota of.
     * @param _tokenAddress The address of the currency that will be used for withdrawal.
     * @dev on the mainnet, the stablecoin will be dynamic.
     */
    function protocolWithdrawal(uint _idTitle, IERC20 _tokenAddress) public onlyOwner{
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

    /// CCIP FUNCTIONS

    /**
     * @notice responsible for receiving and processing the message
     * @param any2EvmMessage CCIP message
     */
    function _ccipReceive( Client.Any2EVMMessage memory any2EvmMessage) internal override onlyWhitelistedSourceChain(any2EvmMessage.sourceChainSelector) onlyWhitelistedSenders(abi.decode(any2EvmMessage.sender, (address))) {
        lastReceivedMessageId = any2EvmMessage.messageId;
        lastReceivedText = abi.decode(any2EvmMessage.data, (bytes));

        bytes32 _permissionHash;
        address _collectionAddress;
        uint _nftId;

        (_permissionHash, _collectionAddress, _nftId) = abi.decode(lastReceivedText, (bytes32, address, uint));

        FujiPermissions storage permission = permissionInfo[_permissionHash];
        TitlesSold storage myTitle = titleSoldInfos[permission.idTitle][permission.contractId];

        myTitle.collateralId = _nftId;
        myTitle.collateralRWAAddress = _collectionAddress;

        if(myTitle.collateralId != 0 && myTitle.collateralRWAAddress != address(0)) {
            myTitle.myTitleStatus = MyTitleWithdrawal.Withdrawal;
        }

        emit MessageReceived( any2EvmMessage.messageId, any2EvmMessage.sourceChainSelector, abi.decode(any2EvmMessage.sender, (address)), abi.decode(any2EvmMessage.data, (string)));
    }

    /**
     * @notice Adds a chain
     * @param _sourceChainSelector ID of the permitted chains
     */
    function addSourceChain( uint64 _sourceChainSelector) external onlyOwner {
        whitelistedSourceChains[_sourceChainSelector] = true;
    }

    /**
     * @notice Removes a chain
     * @param _sourceChainSelector ID of the permitted chains
     */
    function removelistSourceChain( uint64 _sourceChainSelector) external onlyOwner {
        whitelistedSourceChains[_sourceChainSelector] = false;
    }
    
    /**
     * @notice Adds the address that has permission to send messages
     * @param _sender CCIP sender address
     */
    function addSender(address _sender) external onlyOwner {
        whitelistedSenders[_sender] = true;
    }
    
    /**
     * @notice Removes the address that has permission to send messages
     * @param _sender CCIP sender address
     */
    function removeSender(address _sender) external onlyOwner {
        whitelistedSenders[_sender] = false;
    }

    /**
     * @notice This function is responsible for registering the CCIP Receiver in the networks where Horizon operates.
     * @param _receiverAddress Address of the contract on the Avalanche network
     */
    function addReceiver(address _receiverAddress) public onlyOwner {
        fujiReceiver = _receiverAddress;
    }

    /**
    * @notice Fetches the details of the last received message.
    * @return messageId The ID of the last received message.
    * @return text The last received text.
    */
    function getLastReceivedMessageDetails() external view returns (bytes32 messageId, bytes memory text) {
        return (lastReceivedMessageId, lastReceivedText);
    }

    /// MODIFIERS

    modifier onlyWhitelistedSourceChain(uint64 _sourceChainSelector){
        if (!whitelistedSourceChains[_sourceChainSelector])
            revert SourceChainNotWhitelisted(_sourceChainSelector);
        _;
    }

    modifier onlyWhitelistedSenders(address _sender){
        if (!whitelistedSenders[_sender]) revert SenderNotWhitelisted(_sender);
        _;
    }
}