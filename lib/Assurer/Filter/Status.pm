package Assurer::Filter::Status;

use strict;
use warnings;
use base qw( Assurer::Filter );

sub dispatch {
    my ( $self, $result ) = @_;
    my @results = grep { $_ =~ /^$self->{status}/ } @{ $result->text };
    $result->text(\@results);
    return $result;
}

1;
