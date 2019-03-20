pragma solidity ^0.5.2;

contract SmartBond {

	address payable public creator;
	address payable beneficiarioAddress;
	uint ethBalance = 0;
	bool runStatus = true;
    
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
    function getEthBalance() public view returns(uint) {
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