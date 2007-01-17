package Assurer::Plugin::Test::FTP;
use strict;
use warnings;
use base qw( Assurer::Plugin::Test );
use Assurer::Test;
use Net::FTP;

sub run {
    my ( $self, $context, $args ) = @_;

    my $test = $context->test;
    my $conf = $self->conf;

    my $host     = $conf->{host}     || $context->conf->{host};
    my $user     = $conf->{user}     || 'root';
    my $password = $conf->{password} || '';

    my $ftp = Net::FTP->new($host);
    $test->ok($ftp, "connect to $host");
    $test->ok($ftp && $ftp->login($user, $password), "login to $host");
}

1;
__END__

=head1 NAME

Assurer::Plugin::Test::FTP - Test for FTP

=head1 SYNOPSIS

  - module: FTP
    config:
      dsn:      dbi:mysql:;hostname=%s
      user:     root
      password:
    role: ftp

=head1 DESCRIPTION

test ftp.

=head1 AUTHOR

Tokuhiro Matsuno <tokuhiro __AT__ mobilefactory.jp>

