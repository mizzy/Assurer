package Assurer::Filter::Type;

use strict;
use warnings;
use base qw( Assurer::Filter );

sub dispatch {
    my ( $self, $args ) = @_;
    return $args->{format}->type eq $self->{type};
}

1;
