pragma solidity ^0.5.2;

contract SmartBond {

	address payable public creator;
	string  idSM;
	string  beneficiarioNome;
	string  beneficiarioCognome;
	string  beneficiarioCodiceFiscale;
	address payable beneficiarioAddress;
	uint256 dataInizio;
	uint256 dataFine;
	uint    valNominale;
	uint    valCedola;
	uint256 ethBalance;
	string  idCreatoreSM;
	string  oracoloURL;
	bool    runStatus;
    
    // trasferimento ETH
    
    // consente allo SC di ricevere ETH solo dall'owner
    function receiveEth() public payable {
        require(msg.sender == creator);
        ethBalance += msg.value;
    }
    
    // consente allo SC di inviare ETH al beneficiario solo se la chiamata arriva dall'owner
    function sendAmountToBeneficiario(uint payAmount) public {
        require(msg.sender == creator);
        if (ethBalance >= payAmount) {
            beneficiarioAddress.transfer(payAmount);
            ethBalance -= payAmount;
        }
    }
    
    // ritorna l'ammontare di ETH presenti sullo SmartBond
    function getEthBalance() public returns(uint) {
        require(msg.sender == creator);
        return ethBalance;
    }
    
    // Gestione SmartBond
    function killSmartBond() private {
        require(msg.sender == creator);
        selfdestruct(creator);
    }
    
    function editSmartBondWorkState(bool _status) public {
        require(msg.sender == creator);
        runStatus = _status;
    }
    
}