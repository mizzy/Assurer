package Assurer::Test::WWW::Mechanize;

use strict;
use warnings;
use Test::Builder;

use base qw( Test::WWW::Mechanize );

sub new {
    my $class = shift;

    my $self = {
        mech => Test::WWW::Mechanize->new,
    };

    my $test = Test::Builder->new;
    $test->no_plan;

    bless $self, $class;
}

1;
