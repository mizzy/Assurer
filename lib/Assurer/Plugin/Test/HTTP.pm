package Assurer::Plugin::Test::HTTP;

use strict;
use warnings;
use base qw( Assurer::Plugin::Test );
use LWP::UserAgent;
use HTTP::Request;
use Assurer::Test;

sub register {
    my $self = shift;
    $self->register_tests( qw/ status content server / );
}

sub status {
    my ( $self, $context, $args ) = @_;

    my $conf = $self->conf;

    my $host = $conf->{ host } || $context->conf->{ host };
    my $agent = $conf->{ agent }
        || "Assurer/$Assurer::VERSION (http://assurer.jp/)";

    my $port   = $conf->{ port }   || '80';
    my $path   = $conf->{ path }   || '/';
    my $scheme = $conf->{ scheme } || $port eq '80' ? 'http' : 'https';

    # check if the host have allready the scheme and port
    if ($host !~ /$scheme/){
        $host = "$scheme://$host";
    }

    if ($host !~ /$port/){
        $host = "$host:$port";
    }

    if ($host !~ /$path/){
        $host = "$host$path";
    }

    $path = "/$path" if $path !~ m!^/!;
    $self->{ url } = $conf->{ uri } || $host;
    my $code = $conf->{ code } || 200;

    my $ua = LWP::UserAgent->new;
    $ua->agent( $agent );

    my $req = HTTP::Request->new( GET => $self->{ url } );
    $self->{ res } = $ua->request( $req );

    is( $self->{ res }->code,
        $code, "HTTP status code of $self->{url} is 200" );
}

sub content {
    my ( $self, $context, $args ) = @_;

    my $content = $self->conf->{ content };
    if ( $content ) {
        like( $self->{ res }->content,
              qr/$content/, "Content of $self->{url} matches '$content'",
        );
    }
}

sub server {
    my ( $self, $context, $args ) = @_;

    my $server = $self->conf->{ server };
    if ( $server ) {
        is( $self->{ res }->server,
            $server, "HTTPD version is " . $self->{ res }->server );
    }
}

1;
