$(document).ready(function() {
    $('#signup').click(function() {
        $.post('/signup');
    });
});