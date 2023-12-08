// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <=0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";

error NothingToWithdrawal();

/**
 * @title Horizon Staff
 * @author Barba
 * @notice This contract is responsable to Create Payment Schedules, control the dates and calculate applicable interest
 */
contract HorizonStaff is OwnerIsCreator  {

    /// @notice state variables to store interest information
    /// @notice this method applies only in test enviroment
    /// @dev the values are adjusted as needed to test the contract
    uint scheduleId = 1;
    uint public baseInterestRate = 10;
    uint public dailyInterestRate = 3; 
    uint oneDay = 60; //86400
    address owner;

    /// EVENTS

    /// @notice Event emitted when an admin is added
    event AdminADD(address indexed _wallet);
    /// @notice Event emitted when an admin is removed
    event AdminRemoved(address indexed _wallet);
    /// @notice Event emitted when a stablecoin is added
    event TokenAdded(IERC20 tokenAddress, string symbol);
    /// @notice Event emitted when a stablecoin is removed
    event TokenRemoved(string symbol, address _stablecoin );
    /// @notice Event emitted when a new Consórcio Title is create
    event ScheduleCreated(uint _titleId, uint _numPayments, uint titleSchedule);
    /// @notice Event emitted when an installment date is updated
    event InstallmentDateUpdated(uint _installmentNumber, uint _dateOfPayment);    
    /// @notice Event emitted when payment is on schedule
    event TheInstallmenteIsOnTime(uint _paymentDelay);
    /// @notice Event emitted when the payment is late
    event TheInstallmentIsOneDayLate(uint _amountToPay);
    /// @notice Event emitted when the title will be cancelled
    event TheTitleIsCloseToBeCanceled(uint currentInterestRate, uint amountToPay);
    /// @notice Event emitted when a payment is late and the new value is calculated
    event PaymentIsLate(uint currentInterestRate, uint amountToPay);

    /// @notice Struct to admins structure
    struct AdminInfo {
        address wallet;
        bool isAdmin;
    }
    /// @notice Struct to stablecoins info
    struct TokenInfo {        
        string tokenSymbol;
        IERC20 stablecoin;
        bool isStable;
    }
    /// @notice Struct to Consórcio Titles payment schedule
    struct Deadlines {
        uint titleId;
        uint installmentNumber;
        uint participants;
        uint dateOfPayment;
        uint dateOfDraw;
        uint baseInterestRate;
        uint dailyInterestRate;
    }

    /// MAPPINGS

    /// @notice mapping to store the accepted stablecoins
    mapping(IERC20 coinAddress => TokenInfo) public allowedCrypto;
    /// @dev mapping to store the schedule infos
    mapping(uint _titleId => mapping(uint installmentId => Deadlines)) internal schedule;
    /// @notice mapping to store the admins infos
    mapping(address adminWallet => AdminInfo) public staff;

    IERC20 stablecoin;

    constructor (){
        owner = msg.sender;
    }

    /**
     * @notice This function add a new Admin
     * @param _wallet the admin address
     */
    function addAdmin(address _wallet) public onlyOwner{
        require(_wallet != address(0), "Admin wallet can't be empty!");
        require(staff[_wallet].isAdmin == false,"Admin already registered");

        staff[_wallet] = AdminInfo({
            wallet: _wallet,
            isAdmin: true
        });

        emit AdminADD(_wallet);
    }

    /**
     * @notice This function remove an Admin
     * @param _wallet the admin address
     */
    function removeAdmin(address _wallet) public onlyOwner{
        require(_wallet != address(0), "Admin wallet can't be empty!");
        require(staff[_wallet].isAdmin == true);
        
        delete staff[_wallet];

        emit AdminRemoved(_wallet);
    }

    /**
     * @notice This function add a new stablecoin
     * @param _stablecoin stablecoin address
     * @param _tokenSymbol The name of the stablecoin
     * @dev This method is only to test pouposes in testnet
     */
    function addToken(IERC20 _stablecoin, string memory _tokenSymbol) public onlyOwner{
        require(address(_stablecoin) != address(0), "Token address cannot be zero");
        require(allowedCrypto[_stablecoin].stablecoin == IERC20(address(0)), "Token already added");

        allowedCrypto[_stablecoin] = TokenInfo({
            tokenSymbol: _tokenSymbol,
            stablecoin: _stablecoin,
            isStable: true
        });

        emit TokenAdded(_stablecoin, _tokenSymbol);
    }

    /**
     * @notice This function remove a stablecoin
     * @param _stablecoin stablecoin address
     * @dev This method is only to test pouposes in testnet
     */
    function removeToken(IERC20 _stablecoin) public onlyOwner{
        address stablecoinAddress = address(allowedCrypto[_stablecoin].stablecoin);

        require(stablecoinAddress != address(0), "Token address cannot be zero");

        TokenInfo storage tokenToRemove = allowedCrypto[_stablecoin];

        delete allowedCrypto[_stablecoin];

        emit TokenRemoved(tokenToRemove.tokenSymbol, stablecoinAddress);
    }

    /**
     * @notice this functions create the role Title Schedule
     * @param _titleId The Consórcio Title ID
     * @param _numPayments The number of participants
     * @param _closing The date that selling period ends
     */
    function createSchedule(uint _titleId, uint _numPayments, uint _closing) public onlyOwner returns(uint){
        require(_numPayments > 0, "Number of payments must be greater than 0!");
        require(_closing > block.timestamp, "The closing of title selling must be in the future!");

        uint intervalDays = 5 minutes; //  Test pourposes. We can adjust this as needed.

        uint nextDate = _closing + 300; // Test pourposes. We can adjust this as needed.

        for (uint i = 1; i <= _numPayments; i++) {
            require(nextDate > block.timestamp, "Payment date must be in the future!");

            Deadlines memory dates = Deadlines({
                titleId: _titleId,
                installmentNumber: i,
                participants: 0,
                dateOfPayment: nextDate,
                dateOfDraw: nextDate + 300, // Test pourposes. We can adjust this as needed.
                baseInterestRate: baseInterestRate,
                dailyInterestRate: dailyInterestRate
            });

            schedule[scheduleId][i] = dates;

            nextDate = nextDate + intervalDays;
        }

        uint titleSchedule = scheduleId;

        scheduleId ++;

        emit ScheduleCreated(_titleId, _numPayments, titleSchedule);

        return titleSchedule;
    }

    /**
     * @notice This function update a payment date
     * @param _scheduleId The schedule Id that the payment belongs
     * @param _installmentNumber The installment that you want to change the date
     * @param _dateOfPayment The new date to the payment
     */
    function updatePaymentDate(uint _scheduleId, uint _installmentNumber, uint _dateOfPayment) public onlyOwner{
        require(_installmentNumber > 0, "Installment number must be greater than zero!");
        require(schedule[_scheduleId][_installmentNumber].installmentNumber == _installmentNumber, "Installment number must exist!");
        require(_dateOfPayment > schedule[_scheduleId][_installmentNumber].dateOfPayment, "You can only postpone the payment!");

        uint nextDate = _dateOfPayment * (1 minutes);

        require(nextDate - (schedule[_scheduleId][_installmentNumber - 1].dateOfPayment) > 5 minutes, "Must have a period of 30 days between installments!"); // Test pourposes. We can adjust this as needed.

        schedule[_scheduleId][_installmentNumber].dateOfPayment = _dateOfPayment;

        emit InstallmentDateUpdated(_installmentNumber, _dateOfPayment);
    }
    /**
     * @notice This function is responsable to manage the participants of the draws
     * @param _scheduleId  The schedule Id that the payment belongs
     * @param _drawNumber The number of the draw
     */    
    function addParticipantsToDraw(uint _scheduleId, uint _drawNumber) external onlyOwner {
        Deadlines storage deadline = schedule[_scheduleId][_drawNumber];

        deadline.participants++;
    }

    /// INTERESTS

    /**
     * @notice This function is responsable to calculate the interest over the late payment
     * @param _paymentDelay The total late time of the payment
     * @param _scheduleId  The schedule Id that the payment belongs
     * @param _inicialValue The inicial value of the installment
     */
    function calculateDelayedPayment(uint _paymentDelay, uint _scheduleId, uint _inicialValue) external returns(uint) {

        uint inicialValue = _inicialValue;
        uint currentInterestRate;
        uint amountToPay;

        if(_paymentDelay < oneDay){
            currentInterestRate = schedule[_scheduleId][inicialValue].baseInterestRate;

            uint valueWithInterest = (inicialValue * currentInterestRate) / 100;

            amountToPay = inicialValue + valueWithInterest;

            emit TheInstallmentIsOneDayLate(amountToPay);
        }else{
            
            uint daily = schedule[_scheduleId][inicialValue].dailyInterestRate;

            uint totalDailyInterest = (_paymentDelay / oneDay) * daily;

            currentInterestRate = baseInterestRate + totalDailyInterest;

            uint valueWithInterests = (inicialValue * currentInterestRate) / 100;

            amountToPay = inicialValue + valueWithInterests;

            if(currentInterestRate > 40){
                emit TheTitleIsCloseToBeCanceled(currentInterestRate, amountToPay);
            }else{
                emit PaymentIsLate(currentInterestRate, amountToPay);
            }
        }
        return amountToPay;
    }

    /**
     * @notice This function update the interests rate
     * @param _baseRate The interest base rate
     * @param _dailyRate The interest daily rate
     */
    function updateInterest(uint _baseRate, uint _dailyRate) public onlyOwner {
        baseInterestRate = _baseRate;
        dailyInterestRate = _dailyRate;
    }

    /**
     * @notice Regular Chainlink Withdrawal function
     * @param _tokenAddress The token that you want to Withdrawal
     */
    function withdrawalProtocolFee(IERC20 _tokenAddress) public onlyOwner {
        require(allowedCrypto[_tokenAddress].isStable == true, "Token not allowed");

        stablecoin = allowedCrypto[_tokenAddress].stablecoin;

        uint amount = stablecoin.balanceOf(address(this));

        if (amount == 0){
            revert NothingToWithdrawal();
        }
        
        stablecoin.transfer(owner, amount);
    }

    /**
     * @notice This functions moderates the stablecoins that can be used
     * @param _stablecoin The address of the stablecoin
     * @return stablecoinName The name of the available stablecoin
     * @return stableAddress The address of the available stablecoin
     * @return isStable The confirmation that this stablecoin is allowed or not
     */
    function returnAvailableStablecoin(IERC20 _stablecoin) external view returns(string memory, address, bool){
        string memory symbol = allowedCrypto[_stablecoin].tokenSymbol;
        address stableAddress = address(allowedCrypto[_stablecoin].stablecoin); 
        bool isStable = allowedCrypto[_stablecoin].isStable;

        return (symbol, stableAddress, isStable);
    }

    /**
     * @notice This function return the payment deadline
     * @param _scheduleId  The schedule Id that the payment belongs
     * @param _installmentNumber The number of the installment
     */
    function returnPaymentDeadline(uint _scheduleId, uint _installmentNumber) external view returns(uint){
        uint paymentDate = schedule[_scheduleId][_installmentNumber].dateOfPayment;
        return paymentDate;
    }

    /**
     * @notice This function return the draw date
     * @param _scheduleId  The schedule Id that the payment belongs
     * @param _installmentNumber The number of the installment
     */
    function returnDrawDate(uint _scheduleId, uint _installmentNumber) external view returns(uint){
        uint drawDate = schedule[_scheduleId][_installmentNumber].dateOfDraw;
        
        return drawDate;
    }

    /**
     * @notice This function return the total participants of the requested draw
     * @param _scheduleId The schedule Id that the payment belongs
     * @param _drawNumber The number of the draw
     */
    function returnDrawParticipants(uint _scheduleId, uint _drawNumber) public view returns(uint) {
        Deadlines storage deadline = schedule[_scheduleId][_drawNumber];

        return deadline.participants;
    }
}