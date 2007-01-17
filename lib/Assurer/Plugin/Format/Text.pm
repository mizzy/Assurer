package Assurer::Plugin::Format::Text;

use strict;
use warnings;

use base qw( Assurer::Plugin::Format );

sub run {
    my ( $self, $context, $args ) = @_;

    my $format = Assurer::Format->new;
    $format->type('text/plain');

    my $lines;
    for my $model ( @{ $context->results } ) {
        for my $file ( @{ $model->structure->{test_files} } ) {
            $lines .= "Results of $file->{file}\n";
            for my $event ( @{ $file->{events} } ) {
                $lines .= $event->{line} . "\n";
            }
        }
        $lines .= "\n";
    }
    $format->content($lines);

    $context->add_format($format);
}

1;
