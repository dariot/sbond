$(document).ready(function() {	
    $('#issue').click(function() {
        $.get('/issuer/issue');
    });
});