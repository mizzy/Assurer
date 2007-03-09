return if $host !~ /example\.com/;

$mech->get_ok("http://$host", "got htttp://$host");
