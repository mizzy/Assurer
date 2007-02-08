package Assurer::Plugin::Test::FTP;
use strict;
use warnings;
use base qw( Assurer::Plugin::Test );
use Assurer::Test;
use Net::FTP;

sub register {
    my $self = shift;
    $self->register_tests( qw/ connect login / );
}

sub connect {
    my ( $self, $context, $args ) = @_;

    my $conf = $self->conf;
    my $host = $conf->{host} || $context->conf->{host};

    $self->{ftp} = Net::FTP->new($host);
    ok($self->{ftp}, "connect to $host");
}

sub login {
    my ( $self, $context, $args ) = @_;

    my $conf = $self->conf;

    my $host     = $conf->{host}     || $context->conf->{host};;
    my $user     = $conf->{user}     || 'root';
    my $password = $conf->{password} || '';

    ok($self->{ftp} && $self->{ftp}->login($user, $password), "login to $host");
}

1;
__END__

=head1 NAME

Assurer::Plugin::Test::FTP - Test for FTP

=head1 SYNOPSIS

  - module: FTP
    config:
      user:     root
      password:
    role: ftp

=head1 DESCRIPTION

test ftp.

=head1 AUTHOR

Tokuhiro Matsuno <tokuhiro __AT__ mobilefactory.jp>

