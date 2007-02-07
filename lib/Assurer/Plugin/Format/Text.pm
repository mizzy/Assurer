package Assurer::Plugin::Format::Text;

use strict;
use warnings;

use base qw( Assurer::Plugin::Format );

sub run {
    my ( $self, $context, $args ) = @_;

    my $format = Assurer::Format->new;
    $format->type('text/plain');

    my $lines = "Result of $args->{result}->{name}\n";
    $lines .= join "\n", @{ $args->{result}->text };
    $lines .= "\n";
    $format->content($lines);

    $context->add_format($format);
}

1;
