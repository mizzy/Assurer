package Assurer::Plugin::Format;

use strict;
use warnings;

use base qw( Assurer::Plugin );
use Assurer::Format;

sub pre_run {
    my $self = shift;
    return unless Assurer->context->results;
    $self->run(@_);
}

sub id {
   my $self = shift;
   $self->{id} = shift if @_;
   #$self->{id} || $self->url || $self->link;
}

1;
