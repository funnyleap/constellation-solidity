// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <=0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

error NothingToWithdraw();

contract BellumStaff is Ownable {

    using SafeMath for uint256;

    /*Interest variables*/
    uint public baseInterestRate = 10;
    uint public dailyInterestRate = 3;
    uint oneDay = 60; //86400

    /* Events */
    event AdminADD(address indexed _wallet);
    event AdminRemoved(address indexed _wallet);
    event TokenAdded(IERC20 tokenAddress, string symbol);
    event TokenRemoved(string symbol, address _stablecoin );
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
        uint installmentNumber;
        uint participants;
        uint dateOfPayment;
        uint dateOfDraw;
        uint baseInterestRate;
        uint dailyInterestRate;
    }

    /* Mappings */
    mapping(IERC20 coinAddress => TokenInfo) public allowedCrypto;
    mapping(uint scheduleId => mapping(uint installmentId => Deadlines)) internal schedule;
    mapping(address adminWallet => AdminInfo) public staff;

    IERC20 stablecoin;

    constructor (){
    }

    /**
     * 
     * @param _wallet 
     */
    function addAdmin(address _wallet) public {//OK 0x5FA769922a6428758fb44453815e2c436c57C3c7
        require(_wallet != address(0), "Admin wallet can't be empty!");
        require(staff[_wallet].isAdmin == false,"Admin already registered");

        staff[_wallet] = AdminInfo({
            wallet: _wallet,
            isAdmin: true
        });

        emit AdminADD(_wallet);
    }
    /**
     * 
     * @param _wallet 
     */
    function removeAdmin(address _wallet) public {// OK
        require(_wallet != address(0), "Admin wallet can't be empty!");
        require(staff[_wallet].isAdmin == true);
        
        delete staff[_wallet];

        emit AdminRemoved(_wallet);
    }

    /**
     * 
     * @param _stablecoin 
     * @param _tokenSymbol 
     */
    function addToken(IERC20 _stablecoin, string memory _tokenSymbol) public { //OK
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
     * 
     * @param _stablecoin 
     */
    function removeToken(IERC20 _stablecoin) public { //OK
        address stablecoinAddress = address(allowedCrypto[_stablecoin].stablecoin);

        require(stablecoinAddress != address(0), "Token address cannot be zero");

        TokenInfo storage tokenToRemove = allowedCrypto[_stablecoin];

        delete allowedCrypto[_stablecoin];

        emit TokenRemoved(tokenToRemove.tokenSymbol, stablecoinAddress);
    }

    /**
     * 
     * @param _scheduleId 
     * @param _numPayments 
     * @param _closing 
     */
    function createSchedule(uint _scheduleId, uint _numPayments, uint _closing) public {//OK
        require(_scheduleId > 0, "Must set a title number!");
        require(_numPayments > 0, "Number of payments must be greater than 0!");
        require(schedule[_scheduleId][1].installmentNumber == 0, "Schedule Id already used!");

        uint intervalDays = 5 minutes; // We can adjust this as needed.

        uint nextDate = _closing.add(300); // We can adjust this as needed.

        for (uint i = 1; i <= _numPayments; i++) {
            require(nextDate > block.timestamp, "Payment date must be in the future!");

            Deadlines memory dates = Deadlines({
                installmentNumber: i,
                participants: 0,
                dateOfPayment: nextDate,
                dateOfDraw: nextDate.add(300), // We can adjust this as needed.
                baseInterestRate: baseInterestRate,
                dailyInterestRate: dailyInterestRate
            });

            schedule[_scheduleId][i] = dates;

            nextDate = nextDate.add(intervalDays);
        }
    }
    /**
     * 
     * @param _scheduleId 
     * @param _installmentNumber 
     * @param _dateOfPayment 
     */
    function updatePaymentDate(uint _scheduleId, uint _installmentNumber, uint _dateOfPayment) public { //OK
        require(_installmentNumber > 0, "Installment number must be greater than zero!");
        require(schedule[_scheduleId][_installmentNumber].installmentNumber == _installmentNumber, "Installment number must exist!");
        require(_dateOfPayment > schedule[_scheduleId][_installmentNumber].dateOfPayment, "You can only postpone the payment!")

        uint nextDate = _dateOfPayment.mul(1 minutes);

        require(nextDate.sub(schedule[_scheduleId][_installmentNumber.sub(1)].dateOfPayment) > 5 minutes, "Must have a period of 30 days between installments!"); // We can adjust this as needed.

        schedule[_scheduleId][_installmentNumber].dateOfPayment = _dateOfPayment;

        emit InstallmentDateUpdated(_installmentNumber, _dateOfPayment);
    }
    
    /**
     * 
     * @param _scheduleId 
     * @param _drawNumber 
     */
    function addParticipantsToDraw(uint _scheduleId, uint _drawNumber) public {
        Deadlines storage deadline = schedule[_scheduleId][_drawNumber];

        deadline.participants++;
    }

    /* INTERESTS */
    /**
     * 
     * @param _paymentDelay 
     * @param _scheduleId
     * @param _inicialInstallment 
     */
    function calculateDelayedPayment(uint _paymentDelay, uint _scheduleId, uint _inicialInstallment) external returns(uint) { //OK

        uint inicialValue = _inicialInstallment;
        uint currentInterestRate;
        uint amountToPay;


        if(_paymentDelay < oneDay){
            currentInterestRate = schedule[_scheduleId][_installmentNumber].baseInterestRate;

            uint valueWithInterest = (inicialValue.mul(currentInterestRate)).div(100);

            amountToPay = inicialValue.add(valueWithInterest);

            emit TheInstallmentIsOneDayLate(amountToPay);
        }else{
            //Calcula os juros a partir dos dias atrasados
            uint daily = schedule[_scheduleId][_installmentNumber].dailyInterestRate;

            uint totalDailyInterest = (_paymentDelay.div(oneDay)).mul(daily);

            currentInterestRate = baseInterestRate.add(totalDailyInterest);

            uint valueWithInterests = inicialValue.mul(currentInterestRate).div(100);

            //Calcula o valor a pagar a partir do valor inicial + juros(se houver)
            amountToPay = inicialValue.add(valueWithInterests);

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
    function updateInterest(uint _baseRate, uint _dailyRate) public { // OK.
        baseInterestRate = _baseRate;
        dailyInterestRate = _dailyRate;
    }

    /* WITHDRAW */
    /**
     * 
     * @param _tokenAddress 
     */
    function withdrawProtocolFee(IERC20 _tokenAddress) public onlyOwner {//OK
        require(allowedCrypto[_tokenAddress].isStable == true, "Token not allowed");

        stablecoin = allowedCrypto[_tokenAddress].stablecoin;

        uint amount = stablecoin.balanceOf(address(this));

        // Revert if there is nothing to withdraw
        if (amount == 0){
            revert NothingToWithdraw();
        }
        
        stablecoin.transfer(_owner, amount);
    }

    /* GET FUNCTIONS */

    /**
     * 
     * @param _stablecoin 
     * @return _string
     * @return _stablecoin
     * @return _isStable
     */
    function returnAvailableStablecoin(IERC20 _stablecoin) external view returns(string memory, IERC20, bool){//ok
        string symbol = allowedCrypto[_stablecoin].tokenSymbol;
        stablecoin = allowedCrypto[_stablecoin].stablecoin;
        bool isStable = allowedCrypto[_stablecoin].isStable;

        return (symbol, stablecoin, isStable);
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
     * @return _drawDate
     */
    function returnDrawDate(uint _scheduleId, uint _installmentNumber) external view returns(uint){ //OK
        drawDate = schedule[_scheduleId][_installmentNumber].dateOfDraw;
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
}