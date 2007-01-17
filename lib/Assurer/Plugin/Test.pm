package Assurer::Plugin::Test;

use strict;
use warnings;

use base qw( Assurer::Plugin );

sub init {
    my $self = shift;
    $self->{name} ||= 'no name';
    return $self;
}

sub pre_run {
    my $self = shift;
    $self->log( info => qq{Testing $self->{name} ...}, caller => ref $self );
    Assurer->context->test->init($self->{name});

    $self->conf->{host} ||= Assurer->context->conf->{host};

    $self->run(@_);
}

sub post_run {
    my ( $self, $context, $args ) = @_;

    my $test = $context->test;

    my @results = split "\n", ${ $test->{result} };
    my $count = @results;
    push @results, "1..$count";

    my %result = $test->{model}->analyze_fh($self->{name}, \@results);
    $test->{test_file}->{results} = \%result;
    delete $test->{test_file}->{results}{details};

    $test->{model}->{meat}->{end_time} = time;

    Assurer->context->add_result($test->{model});
}

sub conf {
    my $self = shift;
    return $self->{config};
}

1;
