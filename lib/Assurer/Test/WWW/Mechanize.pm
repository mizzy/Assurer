package Assurer::Test::WWW::Mechanize;

use strict;
use warnings;
use Test::WWW::Mechanize;

sub new {
    my $class = shift;

    my $self = {
        mech => Test::WWW::Mechanize->new,
    };

    bless $self, $class;
}

sub get_ok {
    shift->{mech}->get_ok(@_);
}

1;
