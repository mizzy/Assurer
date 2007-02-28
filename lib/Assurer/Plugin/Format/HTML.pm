package Assurer::Plugin::Format::HTML;

use strict;
use warnings;

use base qw( Assurer::Plugin::Format );
use Test::TAP::Model;
use Test::TAP::HTMLMatrix;
use Test::TAP::Model::Visual;

sub run {
    my ( $self, $context, $args ) = @_;

    my $format = Assurer::Format->new;
    $format->type('text/html');

    my $structure;
    for my $result ( @{ $context->results } ) {
        my $model = $self->_make_model($result);
        push @{ $structure->{test_files} }, @{ $model->structure->{test_files} };
    }

    my $model = Test::TAP::Model::Visual->new_with_struct($structure);
    my $v = Test::TAP::HTMLMatrix->new($model);
    $v->{_css_uri} = $self->{config}->{css_uri};
    $format->content($v->html);

    $context->add_format($format);
}

sub _make_model {
    my ( $self, $result ) = @_;

    my $t = Test::TAP::Model->new;
    $t->start_file($result->name)->{results} = $result->strap;

    my ( @events, $count );
    my $total = @{ $result->strap->{details} };
    for ( @{ $result->strap->{details} } ) {
        $count++;

        my ( $str, $line );
        if ( $_->{ok} ) {
            $str  = "ok $count/$total";
            $line = "ok $count - $_->{name}";
        }
        else {
            $str  = "NOK $count";
            $line = "not ok $count - $_->{name}";
        }

        push @events, {
            str => $str,
            num => $count,
            reason => '',
            ok => $_->{ok},
            skip => '',
            pos => undef,
            type => 'test',
            actual_ok => $_->{actual_ok},
            todo => '',
            line => $line,
        };
    }

    $t->{meat}->{test_files}->[0]->{events} = \@events;

    return $t;
}

1;
