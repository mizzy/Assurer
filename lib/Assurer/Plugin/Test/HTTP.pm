package Assurer::Plugin::Test::HTTP;

use strict;
use warnings;
use base qw( Assurer::Plugin::Test );
use LWP::UserAgent;
use HTTP::Request;
use Assurer::Test;

sub register {
    my $self = shift;
    $self->register_tests( qw/ status content server scrape / );
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
    if ($host and $host !~ /$scheme/){
        $host = "$scheme://$host";
    }

    if ($host and $host !~ /$port/){
        $host = "$host:$port";
    }

    if ($host and $host !~ /$path/){
        $host = "$host$path";
    }

    $path = "/$path" if $path !~ m!^/!;
    $self->{uri} = $conf->{uri} || $host;
    my $code = $conf->{code} || 200;

    my $ua = LWP::UserAgent->new;
    $ua->agent($agent);

    my $req = HTTP::Request->new( GET => $self->{uri} );
    $self->{res} = $ua->request($req);

    is( $self->{res}->code,
        $code, "HTTP status code of $self->{uri} is 200" );
}

sub content {
    my ( $self, $context, $args ) = @_;

    my $content = $self->conf->{ content };
    if ( $content ) {
        like( $self->{ res }->content,
              qr/$content/, "Content of $self->{uri} matches '$content'",
        );
    }
}

sub server {
    my ( $self, $context, $args ) = @_;

    my $server = $self->conf->{server};
    if ( $server ) {
        is( $self->{res}->server,
            $server, "HTTPD version is " . $self->{res}->server );
    }
}

sub scrape {
    my ( $self, $context, $args ) = @_;
    my $conf = $self->conf;

    return unless $conf->{scraper};

    require Web::Scraper::Config;
    my $scraper = Web::Scraper::Config->new({ scraper => $conf->{scraper} });
    my $res = $scraper->scrape( URI->new($conf->{uri}) );

    my $match = 0;
    my $v = Data::Visitor::Callback->new(
        value => sub {
            my ( $self, $data ) = @_;
            $match = 1 if $data =~ /$conf->{match}/i;
        }
    );
    $v->visit($res);

    ok($match, "Scraping result contains $conf->{match}");
}

1;

=head1 NAME

Assurer::Plugin::Test::HTTP - Test for HTTP

=head1 SYNOPSIS

  - module: HTTP
    name: Web::Scraper test
    config:
      content: It works!
    role: web

  - module: HTTP
    name: Web::Scraper test
    config:
      uri: http://search.ebay.com/apple-ipod-nano_W0QQssPageNameZWLRS
      scraper:
        - process:
            - table.ebItemlist tr.single
            - auctions[]
            - scraper:
                - process:
                    - h3.ens>a
                    - description
                    - TEXT
      match: white

=head1 DESCRIPTION

HTTP test plugin.

=head1 AUTHOR

Gosuke Miyashita <gosukenator __AT__ gmail.com>


