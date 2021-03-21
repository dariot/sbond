var express = require('express');
var router = express.Router();

/* GET users listing. */
router.get('/', function(req, res, next) {
    var id = req.query.id;
    if (id) {
        //todo
    } else {
        res.render('issuer', { title: 'Issuer Dashboard' });
    }
});

router.get('/issue', function(req, res, next) {
    console.log('issue');
});

module.exports = router;