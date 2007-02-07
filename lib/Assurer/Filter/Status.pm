package Assurer::Filter::Status;

use strict;
use warnings;
use base qw( Assurer::Filter );

sub dispatch {
    my ( $self, $args ) = @_;
    my $result = $args->{result};
    my @results = grep { $_ =~ /^$self->{status}/ } @{ $result->text };
    $result->text(\@results);
    return $result;
}

1;
