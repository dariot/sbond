var express = require('express');
var router = express.Router();

/* GET users listing. */
router.get('/', function(req, res, next) {
  res.render('issuer', { title: 'Issuer Dashboard' });
});

module.exports = router;