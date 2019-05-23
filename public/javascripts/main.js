$(document).ready(function() {
    $('#deploy').click(function(e) {
        e.preventDefault();
        var type = $('#types').val();
        var description = $('#description').val();
        var issuerSpread = $('#issuerSpread').val();
        var valuationDate = $('#valuationDate').val();
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
});