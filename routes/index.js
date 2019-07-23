var express = require('express');
var router = express.Router();
var fs = require('fs');
var solc = require('solc');
var Web3 = require('web3');

/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('index', { title: 'Smart Bond' });
});

router.post('/', function(req, res, next) {
    
    function compilingPreparations() {
        var buildPath = path.resolve(__dirname, 'build');
        fs.removeSync(buildPath);
        return buildPath;
    }
    
    function getImports(dependency) {
        console.log('Searching for dependency: ', dependency);
        switch (dependency) {
            case 'SmartBond_v5.sol':
                return {contents: fs.readFileSync(path.resolve(__dirname, 'contracts', 'SmartBond_v5.sol'), 'utf8')};
            default:
                return {error: 'File not found'}
        }
    }
    
    function compileSources(config) {
        try {
            return JSON.parse(solc.compile(JSON.stringify(config), getImports));
        } catch (e) {
            console.log(e);
        }
    }
    
    var buildPath = compilingPreparations();
    var config = createConfiguration();
    var compiled = compileSources(config);
    
});

module.exports = router;