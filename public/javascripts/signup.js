$(document).ready(function() {
    $('#signup').click(function() {
        var username = $('#username').val();
        var password = $('#password').val();
        
        var data = {
            username: username,
            password: password
        };
        
        $.post('/signup', data);
    });
    
    $('#cancel').click(function() {
        $('#username').val('');
        $('#password').val('');
    });
});