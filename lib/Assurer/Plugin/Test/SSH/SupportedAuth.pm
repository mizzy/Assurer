package Assurer::Plugin::Test::SSH::SupportedAuth;

use strict;
use warnings;
use base qw( Assurer::Plugin::Test );
use Net::Scan::SSH::Server::SupportedAuth qw(:flag);
use Assurer::Test;

sub register {
    my $self = shift;
    $self->register_tests(qw/ connect /);
}

sub connect {
    my ( $self, $context, $args ) = @_;

    my $conf = $self->conf;

    my $host = $conf->{host} || $context->conf->{host};
    my $port = $conf->{port} || 22;

    my $expect;
    for my $v (2,1) {
        unless (exists $conf->{$v}) {
            $expect->{$v} = 0;
            next;
        }
        for my $auth_method (split /,/, $conf->{$v}) {
            $expect->{$v} |= $AUTH_IF{ $auth_method } if exists $AUTH_IF{ $auth_method };
        }
    }

    my $ssh = Net::Scan::SSH::Server::SupportedAuth->new(
        host => $host,
        port => $port,
       );

    my $sa = $ssh->scan;

    $context->log(debug => $host . ': ' . $ssh->dump);
    ok($sa->{2} == $expect->{2} && $sa->{1} == $expect->{1},
       'SSH::SupportedAuth OK'
      );
}

1;
__END__

=head1 NAME

Assurer::Plugin::Test::SSH::SupportedAuth - Test for SSH supported authenication method

=head1 SYNOPSIS

  - module: SSH::SupportedAuth
    name:   SSH-SupportedAuth
    config:
      2: publickey,password
      1: publickey,password
    role: ssh

or

  - module: SSH::SupportedAuth
    name:   allow only SSHv2 publickey auth
    config:
      2: publickey
    role: ssh

=head1 DESCRIPTION

test server by Net::Scan::SSH::Server::SupportedAuth.

=head1 AUTHOR

HIROSE Masaaki <hirose31 __AT__ gmail.com>
