pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

contract SmartBondV01 {
    using ArrayUtil for ArrayUtil;
    
    address[] arrayAddrSmartBond;
    mapping(address => SmartBond) listaSmartBond;
    uint totaleSmartContract = 0;
    
    struct SmartBond {
        string  idSM;
        string  beneficiarioNome;
        string  beneficiarioCognome;
        string  beneficiarioCodiceFiscale;
        address beneficiarioAddress;
        uint256 dataInizio;
        uint256 dataFine;
        uint    valNominale;
        uint    valCedola;
        uint256 ethBalance;
        string  idCreatoreSM;
        address ownerAddress;
        string  oracoloURL;
        bool    runStatus;
    }
    
    // trasferimento ETH
    
    // consente allo SC di ricevere ETH solo dall'owner
    function () public payable {
        require(ownerAddress == msg.sender);
        ethBalance += msg.value;
    }
    
    // consente allo SC di inviare ETH al beneficiario solo se la chiamata arriva dall'owner
    function sendAmountToBeneficiario(uint payAmount) public {
        require(ownerAddress == msg.sender);
        if(ethBalance >= payAmount){
            beneficiarioAddress.transfer(amount);
            ethBalance -= payAmount;
        }
    }
    
    // ritorna l'ammontare di ETH presenti sullo SmartBond
    function getEthBalance () returns(uint){
        require(ownerAddress == msg.sender);
        return ethBalance;
    }
    
    // Gestione SmartBond
    
    function createSmartBond(string _idSM, string _bN, string _bC, string _bCF, address _bA, uint256 _dI, 
            uint256 _dF, uint _vN, uint _vC, string _idC, string _oURL, bool _rS) public {
        listaSmartBond[_bA] = SmartBond(_idSM, _bN, _bC, _bCF, _bA, _dI, _dF, _vN, _vC, 0, _idC, msg.sender, _oURL, _rS);
        arrayAddrSmartBond.push(_bA) -1;
        totaleSmartContract++;
    }
    
    function deleteSmartBondFromList(address _aSM) public {
        require(msg.sender == listaSmartBond[_aSM].ownerAddress);
        killSmartBond(_aSM);
        delete listaSmartBond[_aSM];
        ArrayUtil.RemoveByValue(arrayAddrSmartBond, _aSM);
        totaleSmartContract--;
    }
    
    function killSmartBond(address _aSM) private {
        require(msg.sender == _aSM);
        selfdestruct(_aSM);
    }
    
    function editSmartBondWorkState(address _aSM, bool _status) public {
        require(msg.sender == listaSmartBond[_aSM].ownerAddress);
        SmartBond storage tmpSB = listaSmartBond[_aSM];
        tmpSB.runStatus = _status;
    }
    
    function getListaSmartBondId() public returns(string[] listaSM) {
        string[] storage tmpArrSM;
        if(getNumSmartBond() > 0){
            for (uint i = 0; i < getNumSmartBond(); i++) {
                SmartBond storage tmpSB = listaSmartBond[arrayAddrSmartBond[i]];
                tmpArrSM[i] = tmpSB.idSM;
            }
        }
        return tmpArrSM;
    }
    
    function getSmartBondByAddress(address _aSM) public returns(SmartBond) {
        SmartBond storage tmpSB = listaSmartBond[_aSM];
        return tmpSB;
    }
    
    function getSmartBondDataByAddress(address _aSM) public returns(string idSM, string bN, string bC, string bCF, 
            address bA, uint256 dI, uint256 dF, uint vN, uint vC, string idC, string oURL, bool rS) {
        SmartBond storage tmpSB = listaSmartBond[_aSM];
        
        return (tmpSB.idSM, tmpSB.beneficiarioNome, tmpSB.beneficiarioCognome, tmpSB.beneficiarioCodiceFiscale, 
            tmpSB.beneficiarioAddress, tmpSB.dataInizio, tmpSB.dataFine, tmpSB.valNominale, tmpSB.valCedola, 
            tmpSB.idCreatoreSM, tmpSB.oracoloURL, tmpSB.runStatus);
    }
    
    function getActiveSmartBond() public returns(SmartBond[] listaSM){
        return getAllSmartBondByRunStatus(true);
    }
    
    function getInactiveSmartBond() public returns(SmartBond[] listaSM){
        return getAllSmartBondByRunStatus(false);
    }
    
    function getNumSmartBond() view public returns(uint) {
        return arrayAddrSmartBond.length;
    }
    
    function getAllSmartBondByRunStatus(bool _status) private returns(SmartBond[] listaSM){
        SmartBond[] storage tmpArrSM;
        if(getNumSmartBond() > 0){
            for (uint i = 0; i < getNumSmartBond(); i++) {
                SmartBond storage tmpSB = listaSmartBond[arrayAddrSmartBond[i]];
                if(tmpSB.runStatus == _status){
                    tmpArrSM[i] = tmpSB;
                }
            }
        }
    }
    
}

library ArrayUtil {
  // Trova il valore index di un valore nell'array.
  function IndexOf(address[] values, address value) public returns(uint) {
    uint i = 0;
    while (values[i] != value) {
      i++;
    }
    return i;
  }
  // Rimuovi un elemento da un array.
  function RemoveByValue(address[] values, address value) public {
    uint i = IndexOf(values, value);
    RemoveByIndex(values, i);
  }
  // Rimuovi un elmento da indice index in un array.
  function RemoveByIndex(address[] values, uint i) public {
    while (i<values.length-1) {
      values[i] = values[i+1];
      i++;
    }
  }
}