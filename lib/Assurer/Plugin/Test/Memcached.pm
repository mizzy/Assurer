package Assurer::Plugin::Test::Memcached;

use strict;
use warnings;
use base qw( Assurer::Plugin::Test );
use Assurer::Test;
use Cache::Memcached;

sub register {
    my $self = shift;
    $self->register_tests( qw/ get_slab valid_slab / );
}

sub get_slab {
    my ( $self, $context, $args ) = @_;

    my $conf = $self->conf;

    my $host = $conf->{host} || $context->conf->{host};
    my $port = $conf->{port} || 11211;

    my $memd = Cache::Memcached->new( { servers => ["$host:$port"], } );

    $self->{slabs} = $memd->stats('slabs');
    ok( $self->{slabs}, "can get slabs $host" );
}

sub valid_slab {
    my ( $self, $context, $args ) = @_;
    my $host = $self->conf->{host} || $context->conf->{host};
    if ($self->{slabs}) {
        like( $self->{slabs}->{hosts}->{"$host:$port"}->{slabs}, qr/STAT/, "valid slab $host");
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

