package Assurer::Plugin::Test::HTTP;

use strict;
use warnings;
use base qw( Assurer::Plugin::Test );
use Assurer::Test;
use LWP::UserAgent;
use HTTP::Request;

sub run {
    my ( $self, $context, $args ) = @_;

    my $test = $context->test;
    my $conf = $self->conf;

    my $host = $conf->{host} || $context->conf->{host};
    my $port = $conf->{port} || '80';
    my $path = $conf->{path} || '/';
    $path = "/$path" if $path !~ m!^/!;
    my $url = "http://$host:$port$path";

    my $ua = LWP::UserAgent->new;
    $ua->agent("Assurer/$Assurer::VERSION (http://mizzy.org/)");

    my $req = HTTP::Request->new( GET => $url );
    my $res = $ua->request($req);

    $test->is_num( $res->code, 200, "HTTP status code of $url is 200" );

    my $content = $conf->{content};
    if ( $content ) {
        $test->like(
            $res->content,
            qr/$content/,
            "Content of $url matches '$content'",
        );
    }

}

1;
