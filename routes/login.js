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
	
	if (!username) {
		return res.status(422).json({
			errors: {
				message: 'please write username'
			}
		});
	}
	
	if (!password) {
		res.json({
			errors: {
				message: 'please write password'
			}
		});
	}
    
    var mongodbOptions = {
        useNewUrlParser: true,
        useUnifiedTopology: true
    };
    mongoose.connect('mongodb://localhost:27017/test', mongodbOptions);
    var db = mongoose.connection;
    db.on('error', console.error.bind('connection error:'));
    db.once('open', function() {
		db.collections.users.findOne({
            username: username
        }).then(function(user) {
			var validLogin = isValidLogin(user, username, password);
			if (validLogin) {
				renderBondView(user);
			}
		});
    });
	
	function isValidLogin(user, inputUsr, inputPwd) {
		var isValidLogin = false;
		if (!user) {
			res.json({
				errors: {
					message: 'username not found'
				}
			});
		}
		
		if (user.password !== inputPwd) {
			res.json({
				errors: {
					message: 'invalid password'
				}
			});
		}
		
		isValidLogin = true;
		return isValidLogin;
	}
	
	function renderBondView(user) {
		var path = __dirname.replace('routes', 'views');
		if (user.type === 'I') {
			res.render(path + '/issuer.jade');
		}
	}
});

module.exports = router;