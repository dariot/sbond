var express = require('express');
var router = express.Router();
var path = require('path');
var fs = require('fs-extra');
var solc = require('solc');
var Web3 = require('web3');

/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('index', { title: 'Smart Bond' });
});

router.post('/', function(req, res, next) {
    
    var web3;
    if (typeof web3 !== 'undefined') {
        web3 = new Web3(web3.currentProvider);
    } else {
        web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
    }
    
    web3.eth.getAccounts(function(err, res) {
        var firstAccount = res[0];
    });
    
    var input = {
        language: 'Solidity',
        sources: {
            'SmartBondLast.sol': {
                content: fs.readFileSync('contracts/SmartBondLast.sol', 'utf-8')
            }
        },
        settings: {
            outputSelection: {
                '*': {
                    '*': [ '*' ]
                }
            }
        }
    }
    var output = JSON.parse(solc.compile(JSON.stringify(input)));
    var abi = output.contracts['SmartBondLast.sol'].SmartBondOwnableReview.abi;
    var bytecode = '0x' + output.contracts['SmartBondLast.sol'].SmartBondOwnableReview.evm.bytecode;
    console.log(bytecode);
    var gasEstimate = web3.eth.estimateGas({data: bytecode});
    var SmartBond = web3.eth.contract(JSON.parse(abi));
    
    res.status(200).send();
});

module.exports = router;