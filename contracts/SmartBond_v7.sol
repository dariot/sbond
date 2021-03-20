pragma solidity 0.5.13;

/** Estendo il contratto Ownable (in questa modalità si crea sempre un indirizzo del contratto)
 * Prefissi utilizzati per le variabili:
 * address: indica una variabile di tipo indirizzo
 * fixed: indica una variabile numerica in formato fixed
 * real: indica una variabile numerica in formato naturale, senza alcuna trasformazione
 * euro: indica una variabile numerica che rappresenta un valore in valuta Euro
 * ether: indica una variabile numerica che rappresenta un valore in valuta Ether
 * timestamp: indica una variabile numerica che rappresenta una data in formato TimeStamp
 */
contract SmartBond {

    address payable addressBeneficiary;
    address payable addressOwner;
    
    uint fixedNumCedole; // numero di cedole da pagare.
    uint fixedNumOne; // numero 1.
    uint timestampStartDate; // timestamp di data inizio validità del contratto
    uint realDaysDeltaPaymentDate = 5; // delta di tempo (valore in giorni) entro cui si possono richiedere pagamenti
    
    uint fixedEuroCedolaValue; // valore della cedola in Euro.
    uint realEtherCedolaValue; // valore della cedola in Ether. Valore calcolato al momento della richiesta Pay
    
    uint fixedEuroCapitalValue; // capitale nominale versato dal contraente in Euro.
    uint realEtherCapitalValue; // capitale nominale versato dal contraente in Ether. Valore calcolato al momento della richiesta Pay
    bool capitalPayed = false;
    
    struct PaymentDate {
        bool payed;
        uint timestampDate;
    }
    PaymentDate[] paymentsDate;
    
    /** 
     * Al momento della creazione dello SmartBond assegno: 
     * _addrBeneficiary: beneficiario tramite address
     * _capitalEuro: capitale nominale in euro
     * _interestEuro: totale euro da pagare come interessi
     * _years: numero di anni di validità dello SmartBond
     * _frequency: frequenza di pagamento delle cedole (valore in mesi)
     * _startDate: timestamp UTC della data inizio validità SmartBond. Lavoriamo solo con anni, mesi e giorni.
     * Esempio stringa di inizializzazione SmartBond:
     * 0x14723a09acff6d2a60dcdf7aa4aff308fddc160c,1000,800,2,6,1571097600
     */
    constructor (address payable _addrBeneficiary, uint _capitalEuro, uint _interestEuro, uint _years, uint _frequency, uint _startDate) public {
        addressOwner = msg.sender;
        fixedNumOne = fixed1();
        
        // Inizializzazione variabili
        addressBeneficiary = _addrBeneficiary;
        fixedEuroCapitalValue = newFixed(_capitalEuro);
        timestampStartDate = timestampToParsedTimestamp(_startDate);
        // Calcolo il numero totale di cedole da pagare (in valori fixed point)
        fixedNumCedole = integer(multiply(calcNumCedoleToPayPerYearFixed(newFixed(_frequency)), newFixed(_years)));
        // Calcolo il valore della singola cedola in Euro (in valori fixed point)
        fixedEuroCedolaValue = newFixed(newFixed(_interestEuro)/fixedNumCedole);
        calcPaymentsDate(_frequency);
    }

    /** 
     * Funzione per il caricamento Ether nello SmartContract
     * La quantità deve essere la somma dell'interesse + il capitale nominale versato dal cliente
     */ 
    function depositEther() external payable onlyOwner {
        require(msg.value > 0);
    }
    
    /** Funzione di pagamento cedole e capitale nominale
     * Result "Cedola Payed": Cedola pagata regolarmente
     * Result "Insufficient funds - Cedola value: n": Impossibile pagare la cedola per mancanza di fondi
     * Result "Capital Payed": Capitale nominale pagato regolarmente. Si può procedre con la chiusura del contratto
     * Result "Insufficient funds - Capital value: n": Impossibile pagare il capital enominale per mancanza di fondi
     * Result "Wrong Date": Impossibile richiedere pagamenti perchè non è il giorno corretto 
     */
    function tryToPay(uint _euroEtherValue, uint _timestampRequest) external payable onlyOwner returns(string memory OperationResult) {
        string memory result = "Wrong Date";
        
        // Verifico se la data di richiesta pagamento rientra nel delta valido
        for (uint i=0; i<paymentsDate.length; i++){
            if((paymentsDate[i].payed == false) && checkDate(paymentsDate[i].timestampDate, _timestampRequest, realDaysDeltaPaymentDate)){
                // è possibile procedere con il pagamento
                
                if(fixedNumCedole >= fixedNumOne){
                    // cedole da pagare
                    uint fixedEuroEtherValue = newFixed(_euroEtherValue); // valore di un Ether in Euro. FIXED
                    realEtherCedolaValue = transformFixedToRealEtherValue(calcEtherValueFixed(fixedEuroCedolaValue, fixedEuroEtherValue));
                    if((realEtherCedolaValue > 0) && (address(this).balance >= realEtherCedolaValue)){
                        // balance sufficiente per pagare la cedola
                        sendRealEtherToBeneficiario(realEtherCedolaValue);
                        fixedNumCedole -= fixedNumOne;
                        paymentsDate[i].payed = true;
                        result = "Cedola Payed";
                    } 
                    else {
                        // balance insufficiente, rispondo con la quantità di Ether necessaria da ricaricare
                        result = strConcat("Insufficient funds - Cedola value: ", uint2str(realEtherCedolaValue));
                    }
                }
                break;
            }
        }
        
        if(fixedNumCedole == 0){
            if(!capitalPayed){
                uint fixedEuroEtherValue = newFixed(_euroEtherValue); // valore di un Ether in Euro. FIXED
                // cedole terminate, viene restituito il capitale nominale
                realEtherCapitalValue = transformFixedToRealEtherValue(calcEtherValueFixed(fixedEuroCapitalValue, fixedEuroEtherValue));
                if((realEtherCapitalValue > 0) && (address(this).balance >= realEtherCapitalValue)){
                    // balance sufficiente per pagare il capitale nominale
                    sendRealEtherToBeneficiario(realEtherCapitalValue);
                    result = "Capital Payed";
                    capitalPayed = true;
                }
                else {
                    // balance insufficiente, rispondo con la quantità di Ether necessaria da ricaricare
                    result = strConcat("Insufficient funds - Capital value: ", uint2str(realEtherCapitalValue));
                }
            }
            else{
                result = "Capital Already Payed";
            }
        }
        
        return result;
    }
    
    /** 
     * Aggiorna lo stato dello SmartBond
     * Terminate le cedole, lo SmartBond deve essere chiuso
     * Deve essere invocato quando la funzione tryToPay restituisce "Capital Payed come valore
     */ 
    function updateSmartBondStaus() external payable onlyOwner {
        if(fixedNumCedole == 0){
            selfdestruct(addressOwner);
        }
    }
    
    /** 
     * Termina la validità dello SmartBond e restituisce il balance restante al addressOwner
     * Lasciare esposto questo metodo per sicurezza
     */ 
    function killSmartBond() external onlyOwner {
        selfdestruct(addressOwner);
    }
    
    /** 
     * Invio Ether al beneficiario
     */ 
    function sendRealEtherToBeneficiario(uint _realEtherAmount) internal {
        addressBeneficiary.transfer(_realEtherAmount);
    }
    
    function calcEtherValueFixed(uint _numerator, uint _denominator) internal pure returns(uint) {
        return newFixed(_numerator/_denominator);
    }
    
    /** 
     * Calcolo il numero di cedole per singolo anno Fixed
     */ 
    function calcNumCedoleToPayPerYearFixed(uint _fixedFrequency) internal pure returns(uint) {
        return integer(newFixed(newFixed(12)/_fixedFrequency));
    }
    
    /** 
     * Funzione di calcolo data di pagamento e popolamento oggetti struct PaymentDate 
     * Una volta determinata una data di pagamento viene aggiunta all'array di oggetti PaymentDate
     */ 
    function calcPaymentsDate(uint _frequency) internal {
        uint numCedole = fromFixed(fixedNumCedole);
        
        for(uint i=1; i<=numCedole; i++){
            paymentsDate.push(PaymentDate(false, addMonths(timestampStartDate, _frequency*i)));
        }
    }
    
    /** 
     * Validate request date
     */ 
    function checkDate(uint _timestampValidDate, uint _timestampRequest, uint _realDaysDeltaPaymentDate) internal pure returns (bool result){
        /*uint blockTimeStampRequestDate = DateTimeLib.timestampToParsedTimestamp(block.timestamp);
        
        if(DateTimeLib.subDays(_timestampValidDate, _realDaysDeltaPaymentDate) <= blockTimeStampRequestDate 
            && blockTimeStampRequestDate <= DateTimeLib.addDays(_timestampValidDate, _realDaysDeltaPaymentDate)){
                return true;
        }
        return false;
        */
        if(subDays(_timestampValidDate, _realDaysDeltaPaymentDate) <= _timestampRequest 
            && _timestampRequest <= addDays(_timestampValidDate, _realDaysDeltaPaymentDate)){
                return true;
        }
        return false;
    }

    // ---------- Start Debug Functions ----------
    // Balance..
    function zdebugGetRealEthBalance() public view onlyOwner returns(uint RealEtherBalance) {
        return address(this).balance;
    }
    
    function zdebugGetFEthBalance() public view onlyOwner returns(uint FixedEtherBalance) {
        return transformRealEtherValueToFixed(address(this).balance);
    }
    
    // Capital..
    function zdebugGetFEuroCapital() public view onlyOwner returns(uint FixedEuroCapitalValue) {
        return fixedEuroCapitalValue;
    }
    
    function zdebugGetREtherCapitalValue() public view onlyOwner returns(uint RealEtherCapitalValue) {
        return realEtherCapitalValue;
    }
    
    // Cedole..
    function zdebugGetFEuroCedolaValue() public view onlyOwner returns(uint FixedEuroCedolaValue) {
        return fixedEuroCedolaValue;
    }
    
    function zdebugGetREtherCedolaValue() public view onlyOwner returns(uint RealEtherCedolaValue) {
        return realEtherCedolaValue;
    }
    
    function zdebugGetFNumCedole() public view onlyOwner returns(uint FixedNumCedole) {
        return fixedNumCedole;
    }
    
    function zdebugGetPaymentsDate(uint _index) public view onlyOwner returns(string memory PaymentDateObject) { 
        return strConcat(strConcat("TimeStamp: ", uint2str(paymentsDate[_index].timestampDate)), 
            strConcat(" Payed: ", uint2str(paymentsDate[_index].payed ? 1 : 0)));
    }
    // ---------- End Debug Functions ------------
    
    // ---------- Start Ownable Library ----------
    modifier onlyOwner() {
        require(msg.sender == addressOwner);
        _;
    }
    // ---------- End Ownable Library ------------
    
    // ---------- Start SBUtilityLib Library ----------
    /*
    // DateTime Library
    */
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    /* ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------ */
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }
    /* ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------ */
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }
    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }
    function timestampToParsedTimestamp(uint timestampInput) internal pure returns (uint timestampOutput) {
        timestampOutput = timestampFromDate(getYear(timestampInput), getMonth(timestampInput), getDay(timestampInput));
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    function getYear(uint timestamp) internal pure returns (uint year) {
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        uint year;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        uint year;
        uint month;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    
    /*
    // Fixidity Library
    */
    uint constant realToFixedNum = 1000000000000000000;
    uint constant fixedToRealNum = 1000000;

    /**
     * Indico il numero di cifre dedicate alla parte decimale dei numeri float (52,24).
     */
    function digits() internal pure returns(uint8) {
        return 24;
    }
    /**
     * Rappresenta il numero 1 in libreria fixato con le 24 cifre decimali (come dire 1, 24 zeri)
     */
    function fixed1() internal pure returns(uint256) {
        return 1000000000000000000000000;
    }
    /**
     * @notice The amount of decimals lost on each multiplication operand.
     * @dev Test mulPrecision() equals sqrt(fixed1)
     * Hardcoded to 24 digits.
     */
    function mulPrecision() internal pure returns(uint256) {
        return 1000000000000;
    }
    /**
     * Il numero intero più grande rappresentabile con un valore int256: ((2^255)-1)
     */
    function maxUint256() internal pure returns(uint256) {
        return 57896044618658097711785492504343953926634992332820282019728792003956564819967;
    }
    /**
     * Il numero intero più grande che può essere convertito in tipo fixed point
     * Test maxNewFixed() equals maxInt256() / fixed1()
     * Hardcoded to 24 digits.
     */
    function maxNewFixed() internal pure returns(uint256) {
        return 57896044618658097711785492504343953926634992332820282;
    }
    /**
     * Il numero intero più grande che può essere utilizzato in una addizione
     * @dev Test maxFixedAdd() equals maxInt256()-1 / 2
     * Test add(maxFixedAdd(),maxFixedAdd()) equals maxFixedAdd() + maxFixedAdd()
     * Test add(maxFixedAdd()+1,maxFixedAdd()) throws 
     * Test add(-maxFixedAdd(),-maxFixedAdd()) equals -maxFixedAdd() - maxFixedAdd()
     * Test add(-maxFixedAdd(),-maxFixedAdd()-1) throws 
     */
    function maxFixedAdd() internal pure returns(uint256) {
        return 28948022309329048855892746252171976963317496166410141009864396001978282409983;
    }
    /**
     * Il numero intero più grande che può essere utilizzato in una sottrazione
     * @dev Test maxFixedSub() equals minInt256() / 2
     */
    function maxFixedSub() internal pure returns(uint256) {
        return 28948022309329048855892746252171976963317496166410141009864396001978282409984;
    }
    /**
     * Il numero intero più grande che può essere utilizzato in una moltiplicazione
     * @dev Calculated as sqrt(maxInt256()*fixed1()). 
     * Be careful with your sqrt() implementation. I couldn't find a calculator
     * that would give the exact square root of maxInt256*fixed1 so this number
     * is below the real number by no more than 3*10**28. It is safe to use as
     * a limit for your multiplications, although powers of two of numbers over
     * this value might still work.
     * Test multiply(maxFixedMul(),maxFixedMul()) equals maxFixedMul() * maxFixedMul()
     * Test multiply(maxFixedMul(),maxFixedMul()+1) throws 
     * Test multiply(-maxFixedMul(),maxFixedMul()) equals -maxFixedMul() * maxFixedMul()
     * Test multiply(-maxFixedMul(),maxFixedMul()+1) throws 
     * Hardcoded to 24 digits.
     */
    function maxFixedMul() internal pure returns(uint256) {
        return 240615969168004498257251713877715648331380787511296;
    }
    /**
     * Il numero intero più grande che può essere utilizzato in una divisione come dividendo
     * @dev divide(maxFixedDiv,newFixedFraction(1,fixed1())) = maxInt256().
     * Test maxFixedDiv() equals maxInt256()/fixed1()
     * Test divide(maxFixedDiv(),multiply(mulPrecision(),mulPrecision())) = maxFixedDiv()*(10^digits())
     * Test divide(maxFixedDiv()+1,multiply(mulPrecision(),mulPrecision())) throws
     * Hardcoded to 24 digits.
     */
    function maxFixedDiv() internal pure returns(uint256) {
        return 57896044618658097711785492504343953926634992332820282;
    }
    /**
     * Il numero intero più grande che può essere utilizzato in una divisione come divisore
     * @dev Test maxFixedDivisor() equals fixed1()*fixed1() - Or 10**(digits()*2)
     * Test divide(10**(digits()*2 + 1),10**(digits()*2)) = returns 10*fixed1()
     * Test divide(10**(digits()*2 + 1),10**(digits()*2 + 1)) = throws
     * Hardcoded to 24 digits.
     */
    function maxFixedDivisor() internal pure returns(uint256) {
        return 1000000000000000000000000000000000000000000000000;
    }
    /**
     * Converte un uint256 in un fixed point a 24 decimali
     * @dev Test newFixed(0) returns 0
     * Test newFixed(1) returns fixed1()
     * Test newFixed(maxNewFixed()) returns maxNewFixed() * fixed1()
     * Test newFixed(maxNewFixed()+1) fails
     */
    function newFixed(uint256 x) internal pure returns (uint256) {
        assert(x <= maxNewFixed());
        //assert(x >= minNewFixed());
        return x * fixed1();
    }
    /**
     * Converte un fixed point a 24 decimali in un uint256 
     * library to a non decimal. All decimal digits will be truncated.
     */
    function fromFixed(uint256 x) internal pure returns (uint256) {
        return x / fixed1();
    }
    /**
     * @notice Converts two int256 representing a fraction to fixed point units,
     * equivalent to multiplying dividend and divisor by 10^digits().
     * @dev 
     * Test newFixedFraction(maxFixedDiv()+1,1) fails
     * Test newFixedFraction(1,maxFixedDiv()+1) fails
     * Test newFixedFraction(1,0) fails     
     * Test newFixedFraction(0,1) returns 0
     * Test newFixedFraction(1,1) returns fixed1()
     * Test newFixedFraction(maxFixedDiv(),1) returns maxFixedDiv()*fixed1()
     * Test newFixedFraction(1,fixed1()) returns 1
     * Test newFixedFraction(1,fixed1()-1) returns 0
     */
    function newFixedFraction(uint256 numerator, uint256 denominator) internal pure returns (uint256) {
        assert(numerator <= maxNewFixed());
        assert(denominator <= maxNewFixed());
        assert(denominator != 0);
        uint256 convertedNumerator = newFixed(numerator);
        uint256 convertedDenominator = newFixed(denominator);
        return divide(convertedNumerator, convertedDenominator);
    }
    /**
     * Torna la parte INTERA di un fixed point.
     * Test integer(0) returns 0
     * Test integer(fixed1()) returns fixed1()
     * Test integer(newFixed(maxNewFixed())) returns maxNewFixed()*fixed1()
     * Test integer(-fixed1()) returns -fixed1()
     * Test integer(newFixed(-maxNewFixed())) returns -maxNewFixed()*fixed1()
     */
    function integer(uint256 x) internal pure returns (uint256) {
        return (x / fixed1()) * fixed1(); // Can't overflow
    }
    /**
     * Torna la parte DECIMALE di un fixed point 
     * In the case of a negative number the fractional is also negative.
     * @dev 
     * Test fractional(0) returns 0
     * Test fractional(fixed1()) returns 0
     * Test fractional(fixed1()-1) returns 10^24-1
     * Test fractional(-fixed1()) returns 0
     * Test fractional(-fixed1()+1) returns -10^24-1
     */
    function fractional(uint256 x) internal pure returns (uint256) {
        return x - (x / fixed1()) * fixed1(); // Can't overflow
    }
    /**
     * @notice x+y. If any operator is higher than maxFixedAdd() it 
     * might overflow.
     * In solidity maxInt256 + 1 = minInt256 and viceversa.
     * @dev 
     * Test add(maxFixedAdd(),maxFixedAdd()) returns maxInt256()-1
     * Test add(maxFixedAdd()+1,maxFixedAdd()+1) fails
     * Test add(-maxFixedSub(),-maxFixedSub()) returns minInt256()
     * Test add(-maxFixedSub()-1,-maxFixedSub()-1) fails
     * Test add(maxInt256(),maxInt256()) fails
     * Test add(minInt256(),minInt256()) fails
     */
    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        if (x > 0 && y > 0) assert(z > x && z > y);
        if (x < 0 && y < 0) assert(z < x && z < y);
        return z;
    }
    /**
     * @notice x-y. You can use add(x,-y) instead. 
     * @dev Tests covered by add(x,y)
     */
    function subtract(uint256 x, uint256 y) internal pure returns (uint256) {
        return add(x,-y);
    }
    /**
     * @notice x*y. If any of the operators is higher than maxFixedMul() it 
     * might overflow.
     * @dev 
     * Test multiply(0,0) returns 0
     * Test multiply(maxFixedMul(),0) returns 0
     * Test multiply(0,maxFixedMul()) returns 0
     * Test multiply(maxFixedMul(),fixed1()) returns maxFixedMul()
     * Test multiply(fixed1(),maxFixedMul()) returns maxFixedMul()
     * Test all combinations of (2,-2), (2, 2.5), (2, -2.5) and (0.5, -0.5)
     * Test multiply(fixed1()/mulPrecision(),fixed1()*mulPrecision())
     * Test multiply(maxFixedMul()-1,maxFixedMul()) equals multiply(maxFixedMul(),maxFixedMul()-1)
     * Test multiply(maxFixedMul(),maxFixedMul()) returns maxInt256() // Probably not to the last digits
     * Test multiply(maxFixedMul()+1,maxFixedMul()) fails
     * Test multiply(maxFixedMul(),maxFixedMul()+1) fails
     */
    function multiply(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x == 0 || y == 0) return 0;
        if (y == fixed1()) return x;
        if (x == fixed1()) return y;

        // Separate into integer and fractional parts
        // x = x1 + x2, y = y1 + y2
        uint256 x1 = integer(x) / fixed1();
        uint256 x2 = fractional(x);
        uint256 y1 = integer(y) / fixed1();
        uint256 y2 = fractional(y);
        
        // (x1 + x2) * (y1 + y2) = (x1 * y1) + (x1 * y2) + (x2 * y1) + (x2 * y2)
        uint256 x1y1 = x1 * y1;
        if (x1 != 0) assert(x1y1 / x1 == y1); // Overflow x1y1
        
        // x1y1 needs to be multiplied back by fixed1
        // solium-disable-next-line mixedcase
        uint256 fixed_x1y1 = x1y1 * fixed1();
        if (x1y1 != 0) assert(fixed_x1y1 / x1y1 == fixed1()); // Overflow x1y1 * fixed1
        x1y1 = fixed_x1y1;

        uint256 x2y1 = x2 * y1;
        if (x2 != 0) assert(x2y1 / x2 == y1); // Overflow x2y1

        uint256 x1y2 = x1 * y2;
        if (x1 != 0) assert(x1y2 / x1 == y2); // Overflow x1y2

        x2 = x2 / mulPrecision();
        y2 = y2 / mulPrecision();
        uint256 x2y2 = x2 * y2;
        if (x2 != 0) assert(x2y2 / x2 == y2); // Overflow x2y2

        // result = fixed1() * x1 * y1 + x1 * y2 + x2 * y1 + x2 * y2 / fixed1();
        uint256 result = x1y1;
        result = add(result, x2y1); // Add checks for overflow
        result = add(result, x1y2); // Add checks for overflow
        result = add(result, x2y2); // Add checks for overflow
        return result;
    }
    /**
     * @notice 1/x
     * @dev 
     * Test reciprocal(0) fails
     * Test reciprocal(fixed1()) returns fixed1()
     * Test reciprocal(fixed1()*fixed1()) returns 1 // Testing how the fractional is truncated
     * Test reciprocal(2*fixed1()*fixed1()) returns 0 // Testing how the fractional is truncated
     */
    function reciprocal(uint256 x) internal pure returns (uint256) {
        assert(x != 0);
        return (fixed1()*fixed1()) / x; // Can't overflow
    }
    /**
     * @notice x/y. If the dividend is higher than maxFixedDiv() it 
     * might overflow. You can use multiply(x,reciprocal(y)) instead.
     * There is a loss of precision on division for the lower mulPrecision() decimals.
     * @dev 
     * Test divide(fixed1(),0) fails
     * Test divide(maxFixedDiv(),1) = maxFixedDiv()*(10^digits())
     * Test divide(maxFixedDiv()+1,1) throws
     * Test divide(maxFixedDiv(),maxFixedDiv()) returns fixed1()
     */
    function divide(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == fixed1()) return x;
        assert(y != 0);
        assert(y <= maxFixedDivisor());
        return multiply(x, reciprocal(y));
    }
    /** 
     * Trasformo un numero fixed in un valore reale in Ether
     */ 
    function transformFixedToRealEtherValue(uint _inputFixed) internal pure returns(uint256) {
        return _inputFixed/fixedToRealNum;
    }
    /** 
     * Trasformo un valore reale in Ether in un numero Fixed
     */ 
    function transformRealEtherValueToFixed(uint _inputReal) internal pure returns(uint256) {
        return newFixed(_inputReal)/realToFixedNum;
    }
    
    /*
    // Generic Library
    */
    /** 
     * Convert uint to string 
     */
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) { return "0"; }
        uint j = _i;
        uint len;
        while (j != 0) { len++; j /= 10; }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) { bstr[k--] = byte(uint8(48 + _i % 10)); _i /= 10; }
        return string(bstr);
    }
    /** 
     * Concat 2 strings
     */
    function strConcat(string memory _a, string memory _b) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) {
            bab[k++] = _ba[i];
        }
        for (uint i = 0; i < _bb.length; i++) {
            bab[k++] = _bb[i];
        }
        return string(bab);
    }
    // ---------- End SBUtilityLib Library ------------
}
