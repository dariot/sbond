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
    
    function computeBondValue(valuationDate, frequency, faceValue, coupon, convention, maturity) {

        var i, startDate, endDate, yearFraction, swapRate, discountFactor, cashFlow, dayCount, forwardRate, logDebug = '';
        
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
            yearFraction = frequency * (i + 1) / convention;
            swapRate = -0.004736305;
            discountFactor = 1 / Math.pow(1 + swapRate, yearFraction);
            if (i < numReps - 1) {
                cashFlow = faceValue * (coupon / 100);
            } else {
                cashFlow = faceValue;
            }
            
            bondValue += cashFlow * discountFactor;
            
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