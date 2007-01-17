package Assurer::Plugin::Format::HTML;

use strict;
use warnings;

use base qw( Assurer::Plugin::Format );
use Test::TAP::HTMLMatrix;
use Test::TAP::Model::Visual;

sub run {
    my ( $self, $context, $args ) = @_;

    my $format = Assurer::Format->new;
    $format->type('text/html');

    my $structure;
    for my $model ( @{ $context->results } ) {
        push @{ $structure->{test_files} }, @{ $model->structure->{test_files} };
    }

    my $model = Test::TAP::Model::Visual->new_with_struct($structure);
    my $v = Test::TAP::HTMLMatrix->new($model);
    $v->{_css_uri} = $self->{config}->{css_uri};
    $format->content($v->html);

    $context->add_format($format);
}

1;
