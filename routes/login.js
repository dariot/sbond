var express = require('express');
var router = express.Router();
var mongoose = require('mongoose');

/* GET users listing. */
router.get('/', function(req, res, next) {
    res.render('login', { title: 'Login' });
});

router.post('/', function(req, res, next) {
    var username = req.body.username;
    var password = req.body.password;
    
    var mongodbOptions = {
        useNewUrlParser: true,
        useUnifiedTopology: true
    };
    mongoose.connect('mongodb://localhost:27017/test', mongodbOptions);
    var db = mongoose.connection;
    db.on('error', console.error.bind('connection error:'));
    db.once('open', function() {
        /* todo */
    });
});

module.exports = router;