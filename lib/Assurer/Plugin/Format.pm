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

1;
