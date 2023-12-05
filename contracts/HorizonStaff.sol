// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <=0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error NothingToWithdraw();

/**
 * @title 
 * @author 
 * @notice 
 */
contract HorizonStaff {

    /*Interest variables*/
    uint scheduleId = 1;
    uint public baseInterestRate = 10;
    uint public dailyInterestRate = 3;
    uint oneDay = 60; //86400
    address owner;

    /* Events */
    event AdminADD(address indexed _wallet);
    event AdminRemoved(address indexed _wallet);
    event TokenAdded(IERC20 tokenAddress, string symbol);
    event TokenRemoved(string symbol, address _stablecoin );
    event ScheduleCreated(uint _titleId, uint _numPayments, uint titleSchedule);
    event InstallmentDateUpdated(uint _installmentNumber, uint _dateOfPayment);    
    event TheInstallmenteIsOnTime(uint _paymentDelay);
    event TheInstallmentIsOneDayLate(uint _amountToPay);
    event TheTitleIsCloseToBeCanceled(uint currentInterestRate, uint amountToPay);
    event PaymentIsLate(uint currentInterestRate, uint amountToPay);

    /* Structs */
    struct AdminInfo {
        address wallet;
        bool isAdmin;
    }
    struct TokenInfo {        
        string tokenSymbol;
        IERC20 stablecoin;
        bool isStable;
    }
    struct Deadlines {
        uint titleId;
        uint installmentNumber;
        uint participants;
        uint dateOfPayment;
        uint dateOfDraw;
        uint baseInterestRate;
        uint dailyInterestRate;
    }

    /* Mappings */
    mapping(IERC20 coinAddress => TokenInfo) public allowedCrypto;
    mapping(uint _titleId => mapping(uint installmentId => Deadlines)) internal schedule;
    mapping(address adminWallet => AdminInfo) public staff;

    IERC20 stablecoin;

    constructor (){
        owner = msg.sender;
    }

    function addAdmin(address _wallet) public {
        require(_wallet != address(0), "Admin wallet can't be empty!");
        require(staff[_wallet].isAdmin == false,"Admin already registered");

        staff[_wallet] = AdminInfo({
            wallet: _wallet,
            isAdmin: true
        });

        emit AdminADD(_wallet);
    }

    function removeAdmin(address _wallet) public {
        require(_wallet != address(0), "Admin wallet can't be empty!");
        require(staff[_wallet].isAdmin == true);
        
        delete staff[_wallet];

        emit AdminRemoved(_wallet);
    }

    function addToken(IERC20 _stablecoin, string memory _tokenSymbol) public {
        require(address(_stablecoin) != address(0), "Token address cannot be zero");
        require(allowedCrypto[_stablecoin].stablecoin == IERC20(address(0)), "Token already added");

        allowedCrypto[_stablecoin] = TokenInfo({
            tokenSymbol: _tokenSymbol,
            stablecoin: _stablecoin,
            isStable: true
        });

        emit TokenAdded(_stablecoin, _tokenSymbol);
    }

    function removeToken(IERC20 _stablecoin) public {
        address stablecoinAddress = address(allowedCrypto[_stablecoin].stablecoin);

        require(stablecoinAddress != address(0), "Token address cannot be zero");

        TokenInfo storage tokenToRemove = allowedCrypto[_stablecoin];

        delete allowedCrypto[_stablecoin];

        emit TokenRemoved(tokenToRemove.tokenSymbol, stablecoinAddress);
    }

    /**
     * 
     * @param _titleId 
     * @param _numPayments 
     * @param _closing 
     */
    function createSchedule(uint _titleId, uint _numPayments, uint _closing) public returns(uint){
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
     * 
     * @param _scheduleId 
     * @param _installmentNumber 
     * @param _dateOfPayment 
     */
    function updatePaymentDate(uint _scheduleId, uint _installmentNumber, uint _dateOfPayment) public {
        require(_installmentNumber > 0, "Installment number must be greater than zero!");
        require(schedule[_scheduleId][_installmentNumber].installmentNumber == _installmentNumber, "Installment number must exist!");
        require(_dateOfPayment > schedule[_scheduleId][_installmentNumber].dateOfPayment, "You can only postpone the payment!");

        uint nextDate = _dateOfPayment * (1 minutes);

        require(nextDate - (schedule[_scheduleId][_installmentNumber - 1].dateOfPayment) > 5 minutes, "Must have a period of 30 days between installments!"); // Test pourposes. We can adjust this as needed.

        schedule[_scheduleId][_installmentNumber].dateOfPayment = _dateOfPayment;

        emit InstallmentDateUpdated(_installmentNumber, _dateOfPayment);
    }
    
    function addParticipantsToDraw(uint _scheduleId, uint _drawNumber) public {
        Deadlines storage deadline = schedule[_scheduleId][_drawNumber];

        deadline.participants++;
    }

    /* INTERESTS */

    /**
     * 
     * @param _paymentDelay 
     * @param _scheduleId 
     * @param _inicialValue 
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
     * 
     * @param _baseRate 
     * @param _dailyRate 
     */
    function updateInterest(uint _baseRate, uint _dailyRate) public {
        baseInterestRate = _baseRate;
        dailyInterestRate = _dailyRate;
    }

    /**
     * 
     * @param _tokenAddress 
     */
    function withdrawProtocolFee(IERC20 _tokenAddress) public onlyOwner {
        require(allowedCrypto[_tokenAddress].isStable == true, "Token not allowed");

        stablecoin = allowedCrypto[_tokenAddress].stablecoin;

        uint amount = stablecoin.balanceOf(address(this));

        if (amount == 0){
            revert NothingToWithdraw();
        }
        
        stablecoin.transfer(owner, amount);
    }

    /* GET FUNCTIONS */

    /**
     * 
     * @param _stablecoin 
     * @return 
     * @return 
     * @return 
     */
    function returnAvailableStablecoin(IERC20 _stablecoin) external view returns(string memory, address, bool){//ok
        string memory symbol = allowedCrypto[_stablecoin].tokenSymbol;
        address stableAddress = address(allowedCrypto[_stablecoin].stablecoin); 
        bool isStable = allowedCrypto[_stablecoin].isStable;

        return (symbol, stableAddress, isStable);
    }

    /**
     * 
     * @param _scheduleId 
     * @param _installmentNumber 
     */
    function returnPaymentDeadline(uint _scheduleId, uint _installmentNumber) external view returns(uint){ //OK
        uint paymentDate = schedule[_scheduleId][_installmentNumber].dateOfPayment;
        return paymentDate;
    }

    /**
     * 
     * @param _scheduleId 
     * @param _installmentNumber 
     */
    function returnDrawDate(uint _scheduleId, uint _installmentNumber) external view returns(uint){ //OK
        uint drawDate = schedule[_scheduleId][_installmentNumber].dateOfDraw;
        
        return drawDate;
    }

    /**
     * 
     * @param _scheduleId 
     * @param _drawNumber 
     */
    function returnDrawParticipants(uint _scheduleId, uint _drawNumber) public view returns(uint) {
        Deadlines storage deadline = schedule[_scheduleId][_drawNumber];

        return deadline.participants;
    }

    /* MODIFIERS */
    modifier onlyOwner() {
        require(msg.sender == owner,"The caller must be the owner");
        _;
    }
}