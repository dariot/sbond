pragma solidity ^0.5.1;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * Di default imposto come owner l'indirizzo creatore dello SmartContract 
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * Verifica che il chiamante sia l'owner dello SmartContract
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

library FixidityLib {

    /**
     * Indico il numero di cifre dedicate alla parte decimale dei numeri float (52,24).
     */
    function digits() public pure returns(uint8) {
        return 24;
    }
    
    /**
     * Rappresenta il numero 1 in libreria fixato con le 24 cifre decimali (come dire 1, 24 zeri)
     */
    function fixed1() public pure returns(uint256) {
        return 1000000000000000000000000;
    }

    /**
     * @notice The amount of decimals lost on each multiplication operand.
     * @dev Test mulPrecision() equals sqrt(fixed1)
     * Hardcoded to 24 digits.
     */
    function mulPrecision() public pure returns(uint256) {
        return 1000000000000;
    }

    /**
     * Il numero intero più grande rappresentabile con un valore int256: ((2^255)-1)
     */
    function maxUint256() public pure returns(uint256) {
        return 57896044618658097711785492504343953926634992332820282019728792003956564819967;
    }

    /**
     * Il numero intero più grande che può essere convertito in tipo fixed point
     * Test maxNewFixed() equals maxInt256() / fixed1()
     * Hardcoded to 24 digits.
     */
    function maxNewFixed() public pure returns(uint256) {
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
    function maxFixedAdd() public pure returns(uint256) {
        return 28948022309329048855892746252171976963317496166410141009864396001978282409983;
    }

    /**
     * Il numero intero più grande che può essere utilizzato in una sottrazione
     * @dev Test maxFixedSub() equals minInt256() / 2
     */
    function maxFixedSub() public pure returns(uint256) {
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
    function maxFixedMul() public pure returns(uint256) {
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
    function maxFixedDiv() public pure returns(uint256) {
        return 57896044618658097711785492504343953926634992332820282;
    }

    /**
     * Il numero intero più grande che può essere utilizzato in una divisione come divisore
     * @dev Test maxFixedDivisor() equals fixed1()*fixed1() - Or 10**(digits()*2)
     * Test divide(10**(digits()*2 + 1),10**(digits()*2)) = returns 10*fixed1()
     * Test divide(10**(digits()*2 + 1),10**(digits()*2 + 1)) = throws
     * Hardcoded to 24 digits.
     */
    function maxFixedDivisor() public pure returns(uint256) {
        return 1000000000000000000000000000000000000000000000000;
    }

    /**
     * Converte un uint256 in un fixed point a 24 decimali
     * @dev Test newFixed(0) returns 0
     * Test newFixed(1) returns fixed1()
     * Test newFixed(maxNewFixed()) returns maxNewFixed() * fixed1()
     * Test newFixed(maxNewFixed()+1) fails
     */
    function newFixed(uint256 x) public pure returns (uint256) {
        assert(x <= maxNewFixed());
        //assert(x >= minNewFixed());
        return x * fixed1();
    }

    /**
     * Converte un fixed point a 24 decimali in un uint256 
     * library to a non decimal. All decimal digits will be truncated.
     */
    function fromFixed(uint256 x) public pure returns (uint256) {
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
    function newFixedFraction(uint256 numerator, uint256 denominator) public pure returns (uint256) {
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
    function integer(uint256 x) public pure returns (uint256) {
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
    function fractional(uint256 x) public pure returns (uint256) {
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
    function add(uint256 x, uint256 y) public pure returns (uint256) {
        uint256 z = x + y;
        if (x > 0 && y > 0) assert(z > x && z > y);
        if (x < 0 && y < 0) assert(z < x && z < y);
        return z;
    }

    /**
     * @notice x-y. You can use add(x,-y) instead. 
     * @dev Tests covered by add(x,y)
     */
    function subtract(uint256 x, uint256 y) public pure returns (uint256) {
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
    function multiply(uint256 x, uint256 y) public pure returns (uint256) {
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
    function reciprocal(uint256 x) public pure returns (uint256) {
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
    function divide(uint256 x, uint256 y) public pure returns (uint256) {
        if (y == fixed1()) return x;
        assert(y != 0);
        assert(y <= maxFixedDivisor());
        return multiply(x, reciprocal(y));
    }
}

// Estendo il contratto Ownable (in questa modalità si crea sempre un indirizzo del contratto)
contract SmartBond is Ownable {

    address payable beneficiaryAddress;
    address payable ownerAddress;
    uint256 frequencyFixed; // numero mesi fra una cedola a l'altra. FIXED
    uint256 numCedoleToPayFixed; // numero di cedole da pagare. FIXED
    uint256 cedolaEtherValueFixed; // valore della cedola in Ether. FIXED
    uint256 totalInterestEtherValueToPayFixed; // totale interessi da pagare in Ether. FIXED
    uint256 constant realNumToFixNum = 1000000000000000000;
    uint256 constant fixNumToRealNum = 1000000;
    
    /** Al momento della creazione dello SmartBond assegno: 
    * il beneficiario tramite address
    * la frequenza di pagamento delle cedole (valore in mesi)
    * l'ammontare totale dovuto al beneficiario (valore in Ether: 1 = 1 Ether)
    */
    constructor (address payable _beneficiaryAddress, uint256 _frequency, uint256 _totalInterestEtherValueToPay) public {
        beneficiaryAddress = _beneficiaryAddress;
        frequencyFixed = FixidityLib.newFixed(_frequency);
        ownerAddress = msg.sender;
        totalInterestEtherValueToPayFixed = FixidityLib.newFixed(_totalInterestEtherValueToPay);
        numCedoleToPayFixed = FixidityLib.integer(FixidityLib.divide((FixidityLib.fixed1()*12), frequencyFixed) + (FixidityLib.fixed1()/2));
        cedolaEtherValueFixed = calcCedolaValueFixed();
    }

    /** Consente allo SmartBond di ricevere Ether solo dall'owner
    * il totale ricevuto dovrà essere la somma dell'interesse + il capitale nominale versato dal cliente
    */
    function addEth() public payable onlyOwner {
        require(msg.value > 0);
    }
    
    /** Funzione che si occupa di verificare il numero di cedole da pagare e che commissiona il pagamento della cedola al beneficiario
     * Nel caso la cedola sia l'ultima, viene inviato anche il capitale nominale investito al beneficiario
     */
    function payCedola() public onlyOwner {
        if((FixidityLib.add(FixidityLib.fixed1(),numCedoleToPayFixed)) > FixidityLib.fixed1()){
            sendRealAmountToBeneficiario(transformFixedToRealEtherValue(cedolaEtherValueFixed));
            numCedoleToPayFixed = numCedoleToPayFixed - FixidityLib.fixed1();
        }
        if((FixidityLib.add(FixidityLib.fixed1(),numCedoleToPayFixed)) == FixidityLib.fixed1()){
            numCedoleToPayFixed = FixidityLib.multiply(0,numCedoleToPayFixed);
            sendRealAmountToBeneficiario(address(this).balance);
            killSmartBond();
        }
    }
    
    // Restituisce il bilancio reale di Ether dello SmartBond
    function getRealEthBalance() public view onlyOwner returns(uint) {
        return address(this).balance;
    }
    
    // Restituisce il bilancio fixato di Ether dello SmartBond
    function getFixedEthBalance() public view onlyOwner returns(uint) {
        return transformRealEtherValueToFixed(address(this).balance);
    }
    
    // Termina la validità dello SmartBond e restituisce il balance restante al ownerAddress
    function killSmartBond() public onlyOwner {
        selfdestruct(ownerAddress);
    }
    
    // Calcolo il valore della singola cedola (in valori fixed point)
    function calcCedolaValueFixed() private view returns(uint256) {
        return FixidityLib.divide(totalInterestEtherValueToPayFixed, numCedoleToPayFixed);
    }
    
    // Invio Ether al beneficiario
    function sendRealAmountToBeneficiario(uint256 _payAmount) public payable onlyOwner {
        require(_payAmount > 0 && address(this).balance >= _payAmount);
        beneficiaryAddress.transfer(_payAmount);
    }
    
    // Trasformo un numero fixed in un valore reale in Ether
    function transformFixedToRealEtherValue(uint256 _inputFixed) private pure returns(uint256) {
        return _inputFixed/fixNumToRealNum;
    }
    
    // Trasformo un valore reale in Ether in un numero Fixed
    function transformRealEtherValueToFixed(uint256 _inputReal) private pure returns(uint256) {
        return FixidityLib.newFixed(_inputReal)/realNumToFixNum;
    }

    // ---------- Start Debug Functions ----------
    function debugGetFrequencyFixed() public view onlyOwner returns(uint256) {
        return frequencyFixed;
    }
    
    function debugGetNumCedoleToPayFixed() public view onlyOwner returns(uint256) {
        return numCedoleToPayFixed;
    }
    
    function debugGetTotalInterestEtherValueToPayFixed() public view onlyOwner returns(uint256) {
        return totalInterestEtherValueToPayFixed;
    }
    
    function debugGetCedolaEtherValueFixed() public view onlyOwner returns(uint256) {
        return cedolaEtherValueFixed;
    }
    
    function debugGetCedolaEtherValueReal() public view onlyOwner returns(uint256) {
        return transformFixedToRealEtherValue(cedolaEtherValueFixed);
    }
    
    function debugPayCedolaSimulator() public {
        sendRealAmountToBeneficiario(transformFixedToRealEtherValue(cedolaEtherValueFixed));
        numCedoleToPayFixed = numCedoleToPayFixed - FixidityLib.fixed1();
    }
    
    function testCheckSmartBondState() public view onlyOwner returns(string memory) {
        if((FixidityLib.add(FixidityLib.fixed1(),numCedoleToPayFixed)) > FixidityLib.fixed1()){
            return "Valid";
        }
        if((FixidityLib.add(FixidityLib.fixed1(),numCedoleToPayFixed)) == FixidityLib.fixed1()){
            return "Last Cedola";
        }
        return "Out of range";
    }
    // ---------- End Debug Functions ----------
}