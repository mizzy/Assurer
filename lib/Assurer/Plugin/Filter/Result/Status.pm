package Assurer::Plugin::Filter::Result::Status;

use strict;
use warnings;
use base qw( Assurer::Plugin::Filter::Result );

sub dispatch {
    my ( $self, $result ) = @_;
    my @results = grep { $_ =~ /^$self->{status}/ } @{ $result->text };
    $result->text(\@results);
    return $result;
}

1;
