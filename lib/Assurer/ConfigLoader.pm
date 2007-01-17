package Assurer::ConfigLoader;

use strict;
use warnings;
use Carp;

use YAML;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub load {
    my ( $self, $stuff, $context ) = @_;

    my $config;
    if ( ( !ref($stuff) && $stuff eq '-' ) ||
        ( -e $stuff && -r _) ) {
        $config = YAML::LoadFile($stuff);
        $context->{config_path} = $stuff if $context;
    }
    elsif ( ref($stuff) && ref($stuff) eq 'SCALAR' ) {
        $config = YAML::Load(${$stuff});
    }
    elsif ( ref($stuff) && ref($stuff) eq 'HASH' ) {
        $config = Storable::dclone($stuff);
    }
    else {
        croak "Assurer::ConfigLoader->load: $stuff: $!";
    }

    return $config;
}

1;
