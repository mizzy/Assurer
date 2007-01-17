package Assurer::Test;

use strict;
use warnings;

use Test::Builder;
use Test::TAP::Model;

our $AUTOLOAD;

sub new {
    my $class = shift;
    my $self = { };

    my $test = Test::Builder->new;
    $test->plan('no_plan');
    $test->no_diag(Assurer->context->conf->{no_diag});

    $self->{test} = $test;

    bless $self, $class;
    return $self;
}

sub init {
    my $self = shift;
    my $result;
    open my $out, '>', \$result;
    $self->{test}->output($out);

    $self->{result} = \$result;

    $self->{model} = Test::TAP::Model->new;
    $self->{test_file} = $self->{model}->start_file(shift);
    $self->{model}->{meat}->{start_time} = time;

    $self->{test}->current_test(0);
}

sub AUTOLOAD {
     my $func   = $AUTOLOAD;
     return if $func =~ /::DESTROY$/;

     my ($class,$method) = $func =~ /(.+)::(.+)$/;

     my $code   = sub {
         my $self = shift;
         $self->{test}->$method(@_);
     };

     no strict 'refs';
     *{$func} = $code;
     goto &$code;
}

{
    no warnings 'redefine';
    *Test::Builder::diag = sub {
        my ( $self, @msgs ) = @_;

        return if $self->no_diag;
        return unless @msgs;

        #$diag = join '', map { defined($_) ? $_ : 'undef' } @msgs;
        #$diag =~ s/^/# /gm;
        #$diag .= "\n" unless $diag =~ /\n\Z/;
    };
}

1;
