package Assurer::Result;

use strict;
use warnings;
use Storable;
use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw/ text name /);

sub clone {
    my $self = shift;
    my $clone = Storable::dclone($self);
    return $clone;
}

1;
