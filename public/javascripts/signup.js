$(document).ready(function() {
    $('#signup').click(function() {
        var username = $('#username').val();
        var password = $('#password').val();
        
        var data = {
            username: username,
            password: password
        };
        
        console.log(data);
        
        $.post('/signup', data);
    });
});