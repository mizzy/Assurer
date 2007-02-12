package Assurer::Plugin::Filter::Result::Status;

use strict;
use warnings;
use base qw( Assurer::Plugin::Filter::Result );

sub dispatch {
    my ( $self, $result ) = @_;

    my @results;
    for my $detail ( @{ $result->strap->details } ) {
        if ( $self->{status} eq 'ok' ) {
            push @results, $detail if $detail->{ok};
        }
        else {
            push @results, $detail unless $detail->{ok};
        }
    }

    $result->strap->{details} = \@results;
    return $result;
}

1;
