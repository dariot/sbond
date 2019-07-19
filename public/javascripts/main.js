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