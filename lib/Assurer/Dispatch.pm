package Assurer::Dispatch;

use strict;
use warnings;

use YAML;
use MIME::Base64;
use FindBin;
use POE qw( Wheel::Run );
use Test::TAP::Model;

sub new {
    my ( $class, $args ) = @_;

    my $self = { context => $args->{context} };

    $self->{cmd} = "$FindBin::Bin/assurer_test.pl";

    bless $self, $class;
    return $self;
}

sub run {
    my $self = shift;

    for my $conf ( @{ $self->{context}->{config}->{test} } ) {
        $self->_create_session($conf);
    }

    $poe_kernel->sig( CHLD => '' );
    $poe_kernel->run;
}

sub _create_session {
    my ( $self, $conf ) = @_;

    my $encoded_conf = MIME::Base64::encode( Dump($conf) );
    $encoded_conf =~ s/\n//g;

    my $encoded_context = MIME::Base64::encode( Dump($self->{context}) );

    POE::Session->create(
        inline_states =>
            { _start    => sub {
                  my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];

                  $heap->{name}  = $conf->{name};
                  $heap->{stdout} = [];
                  $heap->{stderr} = [];

                  $heap->{tap} = Test::TAP::Model->new;
                  $heap->{test_file} = $heap->{tap}->start_file( $heap->{name} );
                  $heap->{tap}->{meat}->{start_time} = time;

                  $heap->{child} = POE::Wheel::Run->new(
                      Program     => [ $self->{cmd} ],
                      ProgramArgs => [ "--config=$encoded_conf", "--context=$encoded_context" ],
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
    push @{ $_[HEAP]->{stderr} }, $_[ARG0];
}

sub _close {
    my $self = shift;
    my $heap = $_[HEAP];

    my %result = $heap->{tap}->analyze_fh($self->{name}, $heap->{stdout});
    $heap->{test_file}->{results} = \%result;
    delete $heap->{test_file}->{results}{details};
    $heap->{tap}->{meat}->{end_time} = time;

    $self->{context}->add_result($heap->{tap});

    delete $heap->{child};
}

1;
