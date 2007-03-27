package Assurer::Dispatch;

use strict;
use warnings;

use Assurer::Result;
use YAML;
use MIME::Base64;
use FindBin;
use POE qw( Wheel::Run Component::JobQueue );
use Test::Harness::Straps;
use Storable;

my @jobs;

sub new {
    my ( $class, $args ) = @_;
    my $self = {
        context => $args->{context},
    };

    $self->{cmd} = "$FindBin::Bin/assurer_test.pl";

    if (!-f $self->{cmd}){
        $self->{cmd} = $self->{context}{BaseDir}."/assurer_test.pl";
    }
    bless $self, $class;
    return $self;
}

sub run {
    my $self = shift;

    my $context = $self->{context};

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

    POE::Component::JobQueue->spawn(
        Alias       => 'passive',
        WorkerLimit => $context->conf->{para} || 8,
        Worker      => sub { $self->_create_session },
        Passive => { },
    );

    POE::Session->create(
        inline_states => {
            _start      => sub {
                my $kernel = $_[KERNEL];
                $kernel->yield( 'flood_queue' );
            },
            flood_queue => sub {
                my $kernel = $_[KERNEL];
                foreach ( 0 .. $#jobs ) {
                    $kernel->post( passive => enqueue => response => $_ );
                }
                $kernel->yield( 'dummy' );
            },
            #response    => \&passive_respondee_response,
            # quiets ASSERT_DEFAULT
            _stop       => sub {},
            dummy       => sub {},
        },
    );
    $poe_kernel->sig( CHLD => '' );
    $poe_kernel->run;
}

sub _create_session {
    my $self = shift;

    my $plugin = pop @jobs;

    my $encoded_conf = MIME::Base64::encode( Dump($plugin) );
    $encoded_conf =~ s/\n//g;

    my $encoded_context = MIME::Base64::encode( Dump($self->{context}) );
    $encoded_context =~ s/\n//g;

    my $host = $self->_get_host_exec_on;
    my %program;
    if ( $host ne 'localhost' ) {
        %program = (
            Program     => [ 'ssh' ],
            ProgramArgs => [
                $host,
                $self->{cmd},
                "--config=$encoded_conf",
                "--context=$encoded_context",
            ],
        );
    }
    else {
        %program = (
            Program     => [ $self->{cmd} ],
            ProgramArgs => [
                "--config=$encoded_conf",
                "--context=$encoded_context",
            ],
        );
    }

    POE::Session->create(
        inline_states =>
            { _start    => sub {
                  my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];

                  $heap->{context} = $self->{context};
                  $heap->{name}    = $plugin->{name};
                  $heap->{stdout}  = [];
                  $heap->{stderr}  = [];
                  $heap->{host}    = $plugin->{config}->{host};
                  $heap->{child} = POE::Wheel::Run->new(
                      %program,
                      StdoutEvent => "stdout",
                      StderrEvent => "stderr",
                      CloseEvent  => "close",
                  );
              },
              stdout => \&_stdout,
              stderr => \&_stderr,
              close  => sub { $self->_close(@_) },
          }
        );
}

sub _stdout {
    push @{ $_[HEAP]->{stdout} }, $_[ARG0];
}

sub _stderr {
    my $heap = $_[HEAP];
    my $str = $_[ARG0];

    if ( $str =~ /^Assurer::.+ \[.+\]/ ) {
        warn "$str\n";
    }
    else {
        $heap->{context}->log( debug => $_[ARG0] );
    }
}

sub _close {
    my $self = shift;
    my $heap = $_[HEAP];
    my $name = $heap->{name};
    $name .=  ' on ' . $heap->{host} if $heap->{host};

    my $result = Assurer::Result->new({
        name  => $name,
        host  => $heap->{host},
        strap => Test::Harness::Straps->new->analyze($name, $heap->{stdout}),
    });

    $self->{context}->add_result($result);
    delete $heap->{child};
}

my $cnt = 0;
sub _get_host_exec_on {
    my $self = shift;

    my $hosts = $self->{context}->{config}->{exec_on};
    if ( $hosts ) {
        my $host = $hosts->[$cnt++]->{host};
        $cnt = 0 if $cnt > $#{$hosts};
        return $host;
    }
    else {
        return 'localhost';
    }

}

1;
