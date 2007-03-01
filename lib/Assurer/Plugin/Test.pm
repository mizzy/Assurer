package Assurer::Plugin::Test;

use strict;
use warnings;

use base qw( Assurer::Plugin );
use Assurer::Test;

sub init {
    my $self = shift;
    $self->{name} ||= 'no name';
    $self->{tests} = [];
    $self->{test} = Assurer::Test->new;
    return $self;
}

sub register_tests {
    my ( $self, @tests ) = @_;
    push @{ $self->{tests} }, @tests;
}

sub tests {
    return shift->{tests};
}

sub pre_run {
    my $self = shift;
    my $message = "Testing $self->{name}";
    $message .= ' on ' . $self->conf->{host} . '...' if $self->conf->{host};
    $self->log(
        info   => $message,
        caller => ref $self,
    );
}

sub post_run {
    my ( $self, $context, $args ) = @_;
}

1;
