package Assurer::Dispatch;

use strict;
use warnings;
use Assurer::Result;
use FindBin;
use Test::Harness::Straps;
use Gearman::Client::Async;
use Storable qw( freeze );

sub new {
    my ( $class, $args ) = @_;
    my $self = {
        context => $args->{context},
    };

    bless $self, $class;
    return $self;
}

sub run {
    my $self = shift;

    my $context = $self->{context};

    my @jobs;
    my $hosts = $context->hosts;
    for my $plugin ( @{ $context->{config}->{test} } ) {
        if ( @$hosts and !defined $plugin->{config}->{host} and !defined $plugin->{config}->{uri} ) {
            for my $host ( @$hosts ) {
                next if ( $plugin->{role} and ( !defined $host->{role} or $host->{role} ne $plugin->{role} ) );
                my $clone = Storable::dclone($plugin);
                $clone->{config}->{host} = $host->{host};
                push @jobs, $clone unless $clone->{disable};
            }
        }
        else {
            push @jobs, $plugin unless $plugin->{disable};
        }
    }

    $self->run_tests(@jobs);
}

sub run_tests {
    my ( $self, @jobs ) = @_;

    my $client = Gearman::Client::Async->new( job_servers => ['127.0.0.1'] );

    my ( @tasks, $adder );
    my $i = 0;
    $adder = sub {
        my $plugin = $jobs[$i];
        my $task = Gearman::Task->new(
            'test',
            \( freeze([ $plugin, $self->{context} ]) ),
            +{
                on_complete => sub { $self->on_complete(${$_[0]}, $plugin) }
            },
        );
        $client->add_task($task);
        push @tasks, $task;

        $i++;

        if ( $i < @jobs ) {
            Danga::Socket->AddTimer( 0 => $adder );
        }
    };
    Danga::Socket->AddTimer( 0 => $adder );

    Danga::Socket->SetPostLoopCallback(
        sub { scalar(grep { ! $_->is_finished } @tasks) }
    );

    Danga::Socket->EventLoop;
}

sub on_complete {
    my ( $self, $results, $plugin ) = @_;

    my @results = split '\n', $results;
    my $name   = $plugin->{name};
    my $host   = $plugin->{config}->{host};
    $name .=  ' on ' . $host if $host;

    my $result = Assurer::Result->new({
        name  => $name,
        host  => $host,
        strap => Test::Harness::Straps->new->analyze($name, \@results),
    });

    $self->{context}->add_result($result);
}

1;
