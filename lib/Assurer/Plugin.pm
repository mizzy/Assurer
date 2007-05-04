package Assurer::Plugin;

use strict;
use warnings;
use UNIVERSAL::require;
use base qw( Class::Accessor::Fast );
use FindBin;
use File::Spec;

__PACKAGE__->mk_accessors(qw/ filter /);

sub new {
    my ( $class, $args ) = @_;

    my $self = { %$args };
    bless $self, $class;

    $self->init($args);

    return $self;
}

sub init {

}

sub pre_run  {
    my $self = shift;
    $self->run(@_);
}

sub log {
    my $self = shift;
    $self->{context}->log(@_);
}

sub conf {
    my $self = shift;
    return $self->{config};
}

sub assets_dir {
    my $self = shift;
    my $context = $self->{context};

    if ($self->conf->{assets_path}) {
        return $self->conf->{assets_path};
    }

    my $assets_base = $context->conf->{assets_path}
                   || File::Spec->catfile($FindBin::Bin, "assets");

    return File::Spec->catfile(
        $assets_base, "plugins", $self->class_id,
    );
}

sub class_id {
    my $self = shift;

    my $pkg = ref($self) || $self;
       $pkg =~ s/Assurer::Plugin:://;
    my @pkg = split /::/, $pkg;

    return join '-', @pkg;
}

1;
