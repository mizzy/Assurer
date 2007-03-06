package Assurer::ConfigLoader;

use strict;
use warnings;
use Carp;

use Kwalify qw(validate);
use YAML;

my $assets_dir = File::Spec->catfile($FindBin::Bin, 'assets');

sub new {
    my $class = shift;
    bless {}, $class;
}

sub load {
    my ( $self, $stuff, $context ) = @_;

    $self->{context} = $context;

    my $config;
    if (   ( !ref($stuff) && $stuff eq '-' )
        || ( -e $stuff && -r _ ) )
    {
        $config = YAML::LoadFile($stuff);
        $context->{config_path} = $stuff if $context;
    }
    elsif ( ref($stuff) && ref($stuff) eq 'SCALAR' ) {
        $config = YAML::Load( ${$stuff} );
    }
    elsif ( ref($stuff) && ref($stuff) eq 'HASH' ) {
        $config = Storable::dclone($stuff);
    }
    else {
        croak "Assurer::ConfigLoader->load: $stuff: $!";
    }

    my $schema_file = File::Spec->catfile( $assets_dir, 'kwalify', 'schema.yaml' );
    my $schema = YAML::LoadFile( $schema_file );

    eval { validate( $schema, $config ) };
    $context->error($@) if $@;

    for ( qw/ test format notify publish / ) {
        $self->_validate_plugin_config($config, $_);
    }

    return $config;
}

sub _validate_plugin_config {
    my ( $self, $config, $type ) = @_;

    my $schema_dir = File::Spec->catfile($assets_dir, 'kwalify', 'plugins');

    for my $plugin ( @{ $config->{$type} } ) {
        $type = ucfirst $type;
        my $schema_file = File::Spec->catfile($schema_dir, "$type-$plugin->{module}.yaml");
        next unless -e $schema_file;
        my $schema = YAML::LoadFile( $schema_file );
        eval { validate( $schema, $plugin->{config} ) };
        $self->{context}->error("Config error in ${type}::$plugin->{module}\n$@") if $@;
    }
}

1;
