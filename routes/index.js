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
        web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:7545"));
    }

    web3.eth.getAccounts(function(err, result) {
        var firstAccount = result[0];
        
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
        var bytecode = output.contracts['SmartBondLast.sol'].SmartBondOwnableReview.evm.bytecode;
        var SmartBond = new web3.eth.Contract(abi, firstAccount);
        
        res.status(200).send();
    });
    
});

module.exports = router;