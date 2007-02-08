package Assurer::Plugin::Test::Ping;

use strict;
use warnings;
use base qw( Assurer::Plugin::Test );
use Assurer::Test;
use Net::Ping;

sub register {
    my $self = shift;
    $self->register_tests( qw/ ping / );
}

sub ping {
    my ( $self, $context, $args ) = @_;

    my $conf = $self->conf;

    my $host     = $conf->{host}     || $context->conf->{host};
    my $timeout  = $conf->{timeout}  || 5;
    my $protocol = $conf->{protocol} || 'tcp'; # "tcp", "udp", "icmp", "stream", "syn", or "external". see perldoc Net::Ping.

    my $ping = Net::Ping->new($protocol);
    $ping->hires(1);
    my ($ret,$duration,$ip) = $ping->ping($host, $timeout);
    ok( $ret, "ping ok $host, $ret, $duration, $ip");
}

1;
__END__

=head1 NAME

Assurer::Plugin::Test::Ping - Test for Ping

=head1 SYNOPSIS

  - module: Ping
    config:
      timeout: 9
      protocol: udb
    role: app

=head1 DESCRIPTION

test ping.

=head1 AUTHOR

Tokuhiro Matsuno <tokuhiro __AT__ mobilefactory.jp>

