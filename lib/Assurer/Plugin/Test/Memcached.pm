package Assurer::Plugin::Test::Memcached;

use strict;
use warnings;
use base qw( Assurer::Plugin::Test );
use Assurer::Test;
use Cache::Memcached;

sub run {
    my ( $self, $context, $args ) = @_;

    my $conf = $self->conf;

    my $host = $conf->{host} || $context->conf->{host};
    my $port = $conf->{port} || 11211;

    my $memd = Cache::Memcached->new( { servers => ["$host:$port"], } );

    my $slabs = $memd->stats('slabs');
    ok( $slabs, "can get slabs $host" );
    if ($slabs) {
        like( $slabs->{hosts}->{"$host:$port"}->{slabs}, qr/STAT/, "valid slab $host");
    }
}

1;
__END__

=head1 NAME

Assurer::Plugin::Test::Memcached - Test for Memcached

=head1 SYNOPSIS

  - module: Memcached
    conf:
      port: 11211
    role: memd

=head1 DESCRIPTION

test memcached.

=head1 AUTHOR

Tokuhiro Matsuno <tokuhiro __AT__ mobilefactory.jp>

