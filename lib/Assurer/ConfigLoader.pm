package Assurer::ConfigLoader;

use strict;
use warnings;
use Carp;

use Kwalify qw(validate);
use YAML;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub load {
    my ( $self, $stuff, $context ) = @_;

    my $assets_dir = File::Spec->catfile($FindBin::Bin, 'assets');
    my $schema_file = File::Spec->catfile( $assets_dir, 'kwalify', 'schema.yaml' );

    my $config;
    if (   ( !ref($stuff) && $stuff eq '-' )
        || ( -e $stuff && -r _ ) )
    {
        my $res = validate( YAML::LoadFile($schema_file),
            YAML::LoadFile($stuff) );
        $context->log( error => $res ) unless $res == 1;
        $context->{config_path} = $stuff if $context;
        $config = YAML::LoadFile($stuff);
    }
    elsif ( ref($stuff) && ref($stuff) eq 'SCALAR' ) {
        my $res
            = validate( YAML::LoadFile($schema_file), YAML::Load($stuff) );
        $context->log( error => $res ) unless $res == 1;
        $config = YAML::Load( ${$stuff} );
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
