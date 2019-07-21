$(document).ready(function() {
    
    function showFixedRBFields() {
        $('#valuationDateFG').show();
        $('#frequencyFG').show();
        $('#faceValueFG').show();
        $('#couponFG').show();
        $('#conventionFG').show();
        $('#maturityFG').show();
    }
    
    function showFRNFields() {
        $('#descriptionFG').show();
        $('#issuerSpreadFG').show();
        $('#valuationDateFG').show();
        $('#marketSpreadFG').show();
        $('#frequencyFG').show();
        $('#notionalFG').show();
        $('#indexationFG').show();
        $('#couponFG').show();
        $('#conventionFG').show();
        $('#maturityFG').show();
    }
    
    function hideFields() {
        $('#descriptionFG').hide();
        $('#issuerSpreadFG').hide();
        $('#valuationDateFG').hide();
        $('#faceValueFG').hide();
        $('#marketSpreadFG').hide();
        $('#frequencyFG').hide();
        $('#notionalFG').hide();
        $('#indexationFG').hide();
        $('#couponFG').hide();
        $('#conventionFG').hide();
        $('#maturityFG').hide();
    }    
    
    $('#deploy').click(function(e) {
        e.preventDefault();
        var type = $('#types').val();
        var description = $('#description').val();
        var issuerSpread = $('#issuerSpread').val();
        var valuationDate = $('#valuationDate').val();
        var frequency = $('#frequency').val();
        var faceValue = $('#faceValue').val();
        var marketSpread = $('#marketSpread').val();
        var frequency = $('#frequency').val();
        var notional = $('#notional').val();
        var indexation = $('#indexation').val();
        var coupon = $('#coupon').val();
        var convention = $('#convention').val();
        var maturity = $('#maturity').val();
        
        var bond = {
            'type': type,
            'description': description,
            'issuerSpread': issuerSpread,
            'valuationDate': valuationDate,
            'frequency': frequency,
            'faceValue': faceValue,
            'marketSpread': marketSpread,
            'frequency': frequency,
            'notional': notional,
            'indexation': indexation,
            'coupon': coupon,
            'convention': convention,
            'maturity': maturity
        };
        
        $.ajax({
          type: 'POST',
          data: {
              prova: 'prova'
          },
          url: '/',
          dataType: 'JSON'
        }).done(function( response ) {
            console.log(response);
        });
    });
    
    function toDate(dateStr) {
        var parts = dateStr.split('-');
        return new Date(parts[0], parts[1] - 1, parts[2]);
    }
    
    function getSwapRate(refDate) {
        console.log(refDate);
        var swapRates = {
            '2019-07-18': -0.37,
            '2019-07-19': -0.37,
            '2019-07-22': -0.370002018,
            '2019-07-26': -0.37,
            '2019-08-02': -0.372,
            '2019-08-09': -0.383,
            '2019-08-19': -0.391,
            '2019-09-19': -0.402242401,
            '2019-10-21': -0.430314293,
            '2019-11-19': -0.449567157,
            '2019-12-19': -0.460670963,
            '2020-01-20': -0.473630497,
            '2020-02-19': -0.483866762,
            '2020-03-19': -0.492284952,
            '2020-04-20': -0.502409169,
            '2020-05-19': -0.510606683,
            '2020-06-19': -0.51800366,
            '2020-07-20': -0.524193726,
            '2020-08-19': -0.529458517,
            '2020-09-21': -0.534354589,
            '2020-10-19': -0.538,
            '2020-11-19': -0.541564778,
            '2020-12-21': -0.544708294,
            '2021-01-19': -0.547,
            '2021-02-19': -0.548785465,
            '2021-03-19': -0.549968,
            '2021-04-19': -0.551,
            '2021-05-19': -0.551876738,
            '2021-06-21': -0.552634846,
            '2021-07-19': -0.553,
            '2022-07-19': -0.533000001,
            '2023-07-19': -0.486000002
        }
        
        var currentDate, i, outputSwapRate;
        var keys = Object.keys(swapRates);
        var prevDate = toDate(keys[0]);
        for (var i = 1; i < keys.length; i++) {
            currentDate = toDate(keys[i]);
            if (refDate >= prevDate && refDate <= currentDate) {
                outputSwapRate = swapRates[keys[i]];
                break;
            }
            prevDate = currentDate;
        }
        return outputSwapRate;
    }
    
    function computeBondValue(valuationDate, frequency, faceValue, coupon, convention, maturity) {
        var i, startDate, endDate, yearFraction = 0, swapRate, discountFactor, cashFlow, dayCount, forwardRate, logDebug = '';
        
        frequency = Number.parseFloat(frequency);
        faceValue = Number.parseFloat(faceValue);
        coupon = Number.parseFloat(coupon);
        
        /* first iteration */
        startDate = toDate(valuationDate);
        endDate = new Date();
        endDate.setTime(startDate.getTime() + frequency * 86400000);
        
        maturity = toDate(maturity);
        
        var numDays = (maturity.getTime() - startDate.getTime()) / 86400000;
        var numReps = Math.ceil(numDays / frequency);
        var bondValue = 0;
        for (i = 0; i < numReps; i++) {
            if (endDate > maturity) {
                endDate = maturity;
            }
            
            yearFraction += ((endDate.getTime() - startDate.getTime()) / 86400000) / convention;
            
            /*
            if (i < numReps - 1) {
                yearFraction = frequency * (i + 1) / convention;
            } else {
                yearFraction = frequency * (i + 1) / convention;
            }
            */
            
            swapRate = getSwapRate(endDate);
            discountFactor = 1 / Math.pow(1 + swapRate, yearFraction);
            if (i < numReps - 1) {
                cashFlow = faceValue * (coupon / 100);
            } else {
                cashFlow = faceValue;
            }
            
            bondValue += cashFlow * discountFactor;
            
            startDate = endDate;
            endDate.setTime(startDate.getTime() + frequency * 86400000);
            
            logDebug += yearFraction + ', ' + swapRate + ', ' + discountFactor + ', ' + cashFlow + ', <b>' + bondValue + '</b><div></div>';
        }
        $('#debug').html(logDebug + 'Final Bond Value: <b>' + bondValue + '</b>');
    }
    
    $('#calculate').click(function(e) {
        e.preventDefault();
        
        var valuationDate = $('#valuationDate').val();
        var frequency = $('#frequencies').val();
        var faceValue = $('#faceValue').val();
        var coupon = $('#coupon').val();
        var convention = $('#conventions').val();
        var maturity = $('#maturity').val();
        
        var value = computeBondValue(valuationDate, frequency, faceValue, coupon, convention, maturity);
    });
    
    function setFieldsVisibility(type) {
        hideFields();
        if (type === 'FixedRB') {
            showFixedRBFields();
        } else if (type === 'FRN') {
            showFRNFields();
        }
    }
    
    $('#types').change(function() {
        var type = $('#types').val();
        setFieldsVisibility(type);
    });
    
    hideFields();
    var type = $('#types').val();
    if (type === 'FixedRB') {
        showFixedRBFields();
    } else if (type === 'FRN') {
        showFRNFields();
    }
    
});