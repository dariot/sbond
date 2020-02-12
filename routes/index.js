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
    
    var faceValue = parseFloat(req.body.faceValue);
    var coupon = parseFloat(req.body.coupon);
    var years = 10;
    var frequency = parseFloat(req.body.frequency) / 30;
    var startDate = (new Date(req.body.valuationDate)).getTime();
    var startDateUnixTime = startDate / 1000;
    
    var web3;
    if (typeof web3 !== 'undefined') {
        web3 = new Web3(web3.currentProvider);
    } else {
        web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
    }

    web3.eth.getAccounts(function(err, result) {
        var senderAddress = result[0];
        var beneficiaryAddress = result[1];
        
        var input = {
            language: 'Solidity',
            sources: {
                'SmartBond_v7.sol': {
                    content: fs.readFileSync('contracts/SmartBond_v7.sol', 'utf-8')
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
        var compiledContract = JSON.parse(solc.compile(JSON.stringify(input)));
        
        var abi = compiledContract.contracts['SmartBond_v7.sol'].SmartBond.abi;
        var bytecode = compiledContract.contracts['SmartBond_v7.sol'].SmartBond.evm.bytecode.object;
        var gasEstimate = web3.eth.estimateGas({
            to: beneficiaryAddress,
            data: bytecode
        });
        var SmartBond = new web3.eth.Contract(abi);
        
        var deployArgs = [beneficiaryAddress, faceValue, 800, years, frequency, startDateUnixTime];
        
        SmartBond.deploy({
            data: bytecode
        }).send({
            from: senderAddress,
            gasPrice: 40000000,
            gasLimit: 4000000
        }, function(err, transactionHash) {
            if (err) {
                console.log(err);
            } else {
                console.log(transactionHash);
            }
        });
    });
    
});

module.exports = router;