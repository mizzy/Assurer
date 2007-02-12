package Assurer::Shell;

use strict;
use warnings;
use base qw( Term::Shell );
use Parallel::ForkManager;

sub new {
    my ( $class, $args ) = @_;
    my $self = $class->SUPER::new;

    for ( keys %$args ) {
        $self->{$_} = $args->{$_};
    }

    return $self;
}

sub catch_run {
    my ($self, $cmd, @args) = @_;

    my $pm = Parallel::ForkManager->new( $self->{para} );
    for my $host ( @{ $self->{hosts} } ) {
        $pm->start and next;
        my $out = `ssh $host $cmd @args`;
        chomp $out;
        print "[$host] $out\n";
        $pm->finish;
    }

    $pm->wait_all_children;
}

1;
