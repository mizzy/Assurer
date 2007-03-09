return if $host !~ /example\.com/;

$mech->get_ok("http://$host", "got htttp://$host");
$mech->content_contains('It works!', "Content matches 'It works!'");
