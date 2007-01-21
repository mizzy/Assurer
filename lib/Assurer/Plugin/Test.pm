package Assurer::Plugin::Test;

use strict;
use warnings;

use base qw( Assurer::Plugin );
use Assurer::Test;

sub init {
    my $self = shift;
    $self->{name} ||= 'no name';

    return $self;
}

sub pre_run {
    my $self = shift;
    $self->log( info => qq{Testing $self->{name} ...}, caller => ref $self );
    $self->run(@_);
}

sub post_run {
    my ( $self, $context, $args ) = @_;
}

sub conf {
    my $self = shift;
    return $self->{config};
}

1;
