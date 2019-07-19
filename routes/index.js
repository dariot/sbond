var express = require('express');
var router = express.Router();
var Web3 = require('web3');

/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('index', { title: 'Smart Bond' });
});

router.post('/', function(req, res, next) {
  console.log(Web3);
});

module.exports = router;