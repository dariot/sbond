var express = require('express');
var router = express.Router();
var mongoose = require('mongoose');

router.get('/', function(req, res, next) {
    res.render('register', { title: 'Register' });
});

router.post('/', function(req, res, next) {
    /*
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
        var document = db.collections.users.findOne({
            username: username
        }).exec(function(err, res) {
            if (err) {
                throw err;
            }
            if (res) {
                console.log(res);
            }
            res.status(200).send();
        });
    });
    */
});

module.exports = router;