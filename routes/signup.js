var express = require('express');
var router = express.Router();
var mongoose = require('mongoose');

router.get('/', function(req, res, next) {
    res.render('signup', { title: 'Sign up' });
});

router.post('/', function(req, res, next) {
    var username = req.body.username;
    var password = req.body.password;
    var newUser = {
        username: username,
        password: password
    };
    
    var mongodbOptions = {
        useNewUrlParser: true,
        useUnifiedTopology: true
    };
    mongoose.connect('mongodb://localhost:27017/test', mongodbOptions);
    var db = mongoose.connection;
    db.on('error', console.error.bind('connection error:'));
    db.once('open', function() {
        var users = db.collections.users;
        users.insertOne(newUser);
        res.status(200).send();
    });
});

module.exports = router;