package Assurer::ProcHandler;

use strict;
use warnings;
use Proc::Background;
use FindBin;
use base qw( Class::Accessor::Fast );
use Gearman::Worker;

my $gearman_test_worker  = "$FindBin::Bin/bin/gearman_test_worker.pl";
my $gearman_shell_worker = "$FindBin::Bin/bin/gearman_shell_worker.pl";

sub new {
    my ( $class, $args ) = @_;

    my $self = {
        opts          => { 'die_upon_destroy' => 1 },
        test_workers  => [],
        shell_workers => [],
    };

    bless $self, $class;
    return $self;
}

sub start_gearmand {
    my $self = shift;
    my $gearmand = Assurer->context->conf->{gearman}->{gearmand} || 'gearman';
    $self->{gearmand} = Proc::Background->new( $self->{opts}, $gearmand );

    my $worker = Gearman::Worker->new;
    while ( 1 ) {
        last if $worker->_get_js_sock('127.0.0.1:7003');
        sleep 1;
    }
}

sub start_test_workers {
    my $self = shift;
    for ( 1 .. Assurer->context->conf->{para} ) {
        push @{ $self->{test_workers} },
            Proc::Background->new( $self->{opts}, $gearman_test_worker );
    }
}

sub start_shell_workers {
    my $self = shift;
    for ( 1 .. Assurer->context->conf->{para} ) {
        push @{ $self->{shell_workers} },
            Proc::Background->new( $self->{opts}, $gearman_shell_worker );
    }
}

1;
