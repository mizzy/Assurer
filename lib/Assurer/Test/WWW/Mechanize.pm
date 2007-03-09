package Assurer::Test::WWW::Mechanize;

use strict;
use warnings;
use Test::WWW::Mechanize;
use Test::Builder;

sub new {
    my $class = shift;

    my $self = {
        mech => Test::WWW::Mechanize->new,
    };

    my $test = Test::Builder->new;
    $test->no_plan;

    bless $self, $class;
}

sub get_ok {
    shift->{mech}->get_ok(@_);
}

1;
