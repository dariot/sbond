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
        web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:7545"));
    }
    
    web3.eth.getAccounts().then(function(result) {
        var smartContractName = 'SmartBond_v7.sol';
        var senderAddress = result[0];
        var beneficiaryAddress = result[1];
        
        var content = fs.readFileSync('contracts/' + smartContractName, 'utf-8');
        var input = {
            language: 'Solidity',
            sources: {
                'SmartBond_v7.sol': {
                    content: content
                }
            },
            settings: {
                outputSelection: {
                    '*': {
                        '*': [ '*' ]
                    }
                }
            }
        };
		
		var inputStr = JSON.stringify(input);
		console.log(1);
        var compiled = solc.compile(inputStr);

        fs.writeJsonSync('compiled.txt', compiled);
        //var compiledContract = JSON.parse(compiled);
		
        if (compiled.errors) {
			console.log(compiled.errors);
			return;
		}
		
		var compiledContract = JSON.parse(compiled);
        
        var abi = compiledContract.contracts[smartContractName].SmartBond.abi;
		fs.writeJsonSync('abi.txt', abi);
        var bytecode = compiledContract.contracts[smartContractName].SmartBond.evm.bytecode.object;
		fs.outputFileSync('bytecode.txt', bytecode);
        var gasEstimate = web3.eth.estimateGas({
            to: beneficiaryAddress,
            data: bytecode
        });
        var SmartBond = new web3.eth.Contract(abi);
        
        var deployArgs = [beneficiaryAddress, faceValue, 800, years, frequency, startDateUnixTime];
		
		var testDeployArgs = [beneficiaryAddress, 1000, 800, 2, 6, 1571097600];
		console.log(testDeployArgs);
        
        SmartBond.deploy({
			data: bytecode,
            arguments: testDeployArgs
        }).send({
            from: senderAddress,
            gas: '4700000'
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