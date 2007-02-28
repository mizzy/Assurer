package Assurer::Test;

use strict;
use warnings;

require Exporter;
use vars qw( @ISA @EXPORT $AUTOLOAD );

@ISA = qw( Exporter );
@EXPORT = qw( is like ok );

my $count = 0;

sub new {
    my $class = shift;
    my $self = {
        count => \$count,
    };
    bless $self, $class;
    return $self;
}

sub decr_count {
    my $self = shift;
    ${$self->{count}}--;
}

sub is {
    my ( $got, $expected, $name ) = @_;
    $name ||= '';

    my $result;
    if ( $got eq $expected ) {
        $result = 'ok';
    }
    else {
        $result = 'not ok';
    }

    $count++;
    return "$result $count - $name";
}

sub like {
    my ( $got, $expected, $name ) = @_;
    $name ||= '';

    my $result;
    if ( $got =~ $expected ) {
        $result = 'ok';
    }
    else {
        $result = 'not ok';
    }

    $count++;
    return "$result $count - $name";
}

sub ok {
    my ( $got, $name ) = @_;
    $name ||= '';

    my $result;
    if ( $got ) {
        $result = 'ok';
    }
    else {
        $result = 'not ok';
    }

    $count++;
    return "$result $count - $name";
}

sub DESTROY {
    print "1..$count\n";
}

1;
