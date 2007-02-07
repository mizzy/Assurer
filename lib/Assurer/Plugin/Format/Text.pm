package Assurer::Plugin::Format::Text;

use strict;
use warnings;

use base qw( Assurer::Plugin::Format );

sub run {
    my ( $self, $context, $args ) = @_;

    my $format = Assurer::Format->new;
    $format->type('text/plain');

    my $lines;
    for my $result ( @{ $args->{results} } ) {
        $lines .= 'Result of ' . $result->name . "\n";
        $lines .= join "\n", @{ $result->text };
        $lines .= "\n\n";
    }
    $format->content($lines);

    $context->add_format($format);
}

1;
