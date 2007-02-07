package Assurer::Plugin::Publish::Term;

use strict;
use warnings;

use base qw( Assurer::Plugin::Publish );
use Term::ANSIColor;

sub run {
    my ( $self, $context, $args ) = @_;

    my $format = $args->{format};

    for my $line ( split "\n", $format->content ) {
        if ( $format->type eq 'text/plain' ) {
            if ( $line =~ /^ok/ ) {
                print color 'green';
            }
            elsif ( $line =~ /^not ok/ ) {
                print color 'red';
            }
        }

        print $line . "\n";

        if ( $format->type eq 'text/plain' ) {
            print color 'reset';
        }
    }

    print "\n";
}

1;
