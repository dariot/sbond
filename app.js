var createError = require('http-errors');
var express = require('express');
var path = require('path');
var cookieParser = require('cookie-parser');
var logger = require('morgan');
var MongoClient = require('mongodb').MongoClient;
var DateDiff = require('date-diff');
var cors = require('express-cors');

var indexRouter = require('./routes/index');
var usersRouter = require('./routes/users');
var loginRouter = require('./routes/login');
var issuerRouter = require('./routes/issuer');

var app = express();

var cors = require('cors');    
app.use(cors({credentials: true, origin: 'http://localhost:3000'}));

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');

app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

app.use('/', indexRouter);
app.use('/users', usersRouter);
app.use('/login', loginRouter);
app.use('/issuer', issuerRouter);

const port = 3000;
app.get('/', (req, res) => res.send('Hello World!'));

app.listen(port, () => console.log(`Example app listening on port ${port}!`))

function toDate(dateStr) {
  var parts = dateStr.split("/");
  return new Date(parts[2], parts[1] - 1, parts[0]);
}

function testOracle() {
    MongoClient.connect('mongodb://localhost:27017', {useNewUrlParser: true}, function (err, client) {
        if (err) throw err;

        var db = client.db('smartbond');
        var riga01 = {
            mid_zero_swap: '4.76',
            start_date: '15/10/2012',
            end_date: '15/01/2013',
            day_count: '',
            discount_factor: '',
            forward_rate: ''
        };
        var riga02 = {
            mid_zero_swap: '5.08',
            start_date: '15/10/2013',
            end_date: '15/04/2013',
            day_count: '',
            discount_factor: '',
            forward_rate: ''
        };

        function computeBondValues(err, result) {
            if (err) throw err;

            var i, midZeroSwap, startDate, endDate, discountFactor, dayCount, forwardRate;
            var factor = 0.0028;
            for (i = 0; i < result.length; i++) {
                midZeroSwap = parseFloat(result[i].mid_zero_swap) / 100;
                startDate = result[i].start_date;
                endDate = result[i].end_date;

                /* day count */
                startDate = toDate(startDate);
                endDate = toDate(endDate);
                var diff = new DateDiff(endDate, startDate);
                dayCount = diff.days() * factor;
                result[i].day_count = dayCount;

                /* discount factor */
                discountFactor = Math.pow(1 / (1 + midZeroSwap), dayCount);
                result[i].discount_factor = discountFactor;

                /* forward rate */
                if (i > 0) {
                    forwardRate = ((result[i - 1].discount_factor / discountFactor) - 1) * (365 / (diff.days()));
                }
                
                db.collection('DATI_ORACOLO').updateOne(
                    {id: result[i].id},
                    {$set: {
                            day_count: dayCount,
                            discount_factor: discountFactor,
                            forward_rate: forwardRate
                        }
                    },
                    {upsert: true}
                );
            }
        }

        function insertCallback(err, res) {
            if (err) throw err;

            db.collection('DATI_ORACOLO').find().toArray(computeBondValues);
        }

        db.collection('DATI_ORACOLO').deleteMany();
        db.collection('DATI_ORACOLO').insertMany([riga01, riga02], insertCallback);
    });
}
//testOracle();

// catch 404 and forward to error handler
app.use(function(req, res, next) {
    next(createError(404));
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});

module.exports = app;