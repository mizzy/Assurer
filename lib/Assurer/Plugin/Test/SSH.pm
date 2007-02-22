package Assurer::Plugin::Test::SSH;

use strict;
use warnings;
use base qw( Assurer::Plugin::Test );
use Net::Scan::SSH::Server::Version;
use Assurer::Test;

sub register {
    my $self = shift;
    $self->register_tests(qw/ connect /);
}

sub connect {
    my ( $self, $context, $args ) = @_;

    my $conf = $self->conf;

    my $host    = $conf->{host}    || $context->conf->{host};
    my $port    = $conf->{port}    || 22;
    my $timeout = $conf->{timeout} || 8;

    my $ssh = Net::Scan::SSH::Server::Version->new(
        {   host    => $host,
            timeout => $timeout,
            port    => $port,
        }
    );

    my $results = $ssh->scan;
    like( $results, qr/SSH-.*/, "SSH Connection is up" );
}

1;
__END__

=head1 NAME

Assurer::Plugin::Test::SSH - Test for SSH

=head1 SYNOPSIS

  - module: SSH
	name: SSH Test
    config:
      timeout: 5
    role: ssh
	
=head1 DESCRIPTION

test server by Net::Scan::SSH::Server::Version.

=head1 AUTHOR

Franck Cuny <franck.cuny __AT__ gmail.com>

