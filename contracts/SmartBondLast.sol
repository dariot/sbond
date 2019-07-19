pragma solidity ^0.5.2;

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

// Estendo il contratto Ownable (in questa modalità si crea sempre un indirizzo del contratto)
contract SmartBondOwnableReview is Ownable {

    address payable beneficiarioAddress;
    address payable creatorAddress;
    uint frequency;
    uint cedolaToPay;
    uint256 cedolaValue; // numero di cedole da pagare
    uint256 interestValue;
    
    // Al momento della creazione dello SmartBond assegno: 
    // il beneficiario tramite address
    // la frequenza di pagamento delle cedole (valore in mesi)
    // il totale dell'interesse dovuto (valore in ETH)
    constructor (address payable _beneficiarioAddress, uint _frequency, uint256 _interestValue) public {
        beneficiarioAddress = _beneficiarioAddress;
        frequency = _frequency;
        creatorAddress = msg.sender;
        interestValue = _interestValue;
        cedolaValue = calcCedolaValue(_frequency, _interestValue);
        cedolaToPay = 12 / _frequency;
    }

    // Gestione bilancio ETH
    // consente allo SmartBond di ricevere ETH solo dall'owner
    // il totale ricevuto dovrà essere la somma dell'interesse + il capitale nominale versato dal cliente
    function receiveEth() public payable onlyOwner {
        require(msg.value > 0);
    }
    
    function payCedola() public onlyOwner {
        if(cedolaToPay > 1){
            sendAmountToBeneficiario(cedolaValue / 1000);
            cedolaToPay--;
        }
        if(cedolaToPay == 1){
            sendAmountToBeneficiario(address(this).balance);
            cedolaToPay--;
            killSmartBond();
        }
    }
    
    // Torna il bilancio di ETH presenti sullo SmartBond
    function getEthBalance() public view onlyOwner returns(uint) {
        return address(this).balance;
    }
    
    // Termina la validità dello SmartBond e restituisce il balance al creatorAddress se > 0
    function killSmartBond() public onlyOwner {
        selfdestruct(creatorAddress);
    }
    
    // Determino il valore della singola cedola
    function calcCedolaValue(uint _frequency, uint256 _interestValue) private returns(uint256) {
        cedolaValue = (_interestValue / _frequency) * 1000; // gestione per memorizzare valori decimal in int
    }
    
    // Invio ETH al beneficiario
    function sendAmountToBeneficiario(uint _payAmount) private {
        require(_payAmount > 0 && address(this).balance >= _payAmount);
        beneficiarioAddress.transfer(_payAmount);
    }
}