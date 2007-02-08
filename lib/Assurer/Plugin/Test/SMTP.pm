package Assurer::Plugin::Test::SMTP;

use strict;
use warnings;
use base qw( Assurer::Plugin::Test );
use Assurer::Test;
use Net::SMTP;

sub register {
    my $self = shift;
    $self->register_tests( qw/ connect / );
}

sub connect {
    my ( $self, $context, $args ) = @_;

    my $conf = $self->conf;

    my $host     = $conf->{host}     || $context->conf->{host};
    my $timeout  = $conf->{timeout}  || 10;

    my $smtp = Net::SMTP->new(Host => $host, Timeout => $timeout);
    ok($smtp, "smtp ok $host");
}

1;
__END__

=head1 NAME

Assurer::Plugin::Test::SMTP - Test for SMTP

=head1 SYNOPSIS

  - module: SMTP
    config:
      timeout: 5
    role: smtp

=head1 DESCRIPTION

test server by SMTP.pm.

=head1 AUTHOR

Tokuhiro Matsuno <tokuhiro __AT__ mobilefactory.jp>

