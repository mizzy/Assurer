package Assurer::Plugin::Test::IMAP;

use strict;
use warnings;
use base qw( Assurer::Plugin::Test );
use Net::IMAP::Simple;
use Assurer::Test;

sub register {
    my $self = shift;
    $self->register_tests(qw/ connect /);
}

sub connect {
    my ( $self, $context, $args ) = @_;

    my $conf = $self->conf;

    my $host    = $conf->{host}    || $context->conf->{host};
    my $port    = $conf->{port}    || 143;
    my $timeout = $conf->{timeout} || 90;

    my $imap = Net::IMAP::Simple->new( $host,
        [ port => $port, timeout => $timeout ] );

    ok( $imap, "imap ok $host" );
}

1;
__END__

=head1 NAME

Assurer::Plugin::Test::IMAP - Test for IMAP

=head1 SYNOPSIS

  - module: IMAP
	name: IMAP Test
    config:
      timeout: 5
    role: imap
	
=head1 DESCRIPTION

test server by Net::IMAP::Simple.

=head1 AUTHOR

Franck Cuny <franck.cuny __AT__ gmail.com>

