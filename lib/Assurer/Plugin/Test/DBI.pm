package Assurer::Plugin::Test::DBI;

use strict;
use warnings;
use base qw( Assurer::Plugin::Test );
use Assurer::Test;
use DBI;

sub run {
    my ( $self, $context, $args ) = @_;

    my $conf = $self->conf;

    my $host     = $conf->{host}     || $context->conf->{host};
    my $user     = $conf->{user}     || 'root';
    my $password = $conf->{password} || '';
    my $dsn      = $conf->{dsn}      or do {
        return $context->log(error => 'missing dsn');
    };

    my $dbh;
    eval {
        $dbh = DBI->connect( sprintf( $dsn, $host ),
            $user, $password, { RaiseError => 1, AutoCommit => 1 } );
    };
    ok(! $@, "not error $@");
    ok($dbh && $dbh->ping, 'ping');
}

1;
__END__

=head1 NAME

Assurer::Plugin::Test::DBI - Test for DBI

=head1 SYNOPSIS

  - module: DBI
    config:
      dsn:      dbi:mysql:;hostname=%s
      user:     root
      password:
    role: db

=head1 DESCRIPTION

test server by DBI.pm.

=head1 AUTHOR

Tokuhiro Matsuno <tokuhiro __AT__ mobilefactory.jp>

