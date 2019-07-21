var express = require('express');
var router = express.Router();
var Web3 = require('web3');

/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('index', { title: 'Smart Bond' });
});

router.post('/', function(req, res, next) {
    var accounts = [{
        address: '0x210a6796B73A3a2e9eb2823EeF5494607BB4E822',
        key: 'a3dca6809678c6e642b67f8dcbc5204ce83d3fe8f3e53c1993e9f3d8f86de2b2'
    }];
    var selectedHost = 'http://127.0.0.1:7545';
    
    var gasPrice = web3.eth.gasPrice;
    var gasPriceHex = web3.toHex(gasPrice);
    var gasLimitHex = web3.toHex(6000000);
    var nonce =  web3.eth.getTransactionCount(accounts[selectedAccountIndex].address, 'pending');
    var nonceHex = web3.toHex(nonce);
    
    var abi = jsonOutput['contracts'][contract][path.parse(contract).name]['abi'];
    // Retrieve the byte code
    var bytecode = jsonOutput['contracts'][contract][path.parse(contract).name]['evm']['bytecode']['object'];
    var tokenContract = web3.eth.contract(abi);

});

module.exports = router;