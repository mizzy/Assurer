package Assurer::Plugin;

use strict;
use warnings;
use UNIVERSAL::require;
use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors(qw/ filter /);

sub new {
    my ( $class, $args ) = @_;

    my $self = { %$args };
    bless $self, $class;

    $self->init;

    return $self;
}

sub init {

}

sub pre_run  {
    my $self = shift;
    $self->run(@_);
}

sub log {
    my $self = shift;
    $self->{context}->log(@_);
}

1;
