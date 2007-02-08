package Assurer::Plugin::Filter::Format::Type;

use strict;
use warnings;
use base qw( Assurer::Plugin::Filter::Format );

sub dispatch {
    my ( $self, $args ) = @_;
    return $args->{format}->type eq $self->{type};
}

1;
