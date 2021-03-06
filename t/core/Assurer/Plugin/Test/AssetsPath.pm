package Assurer::Plugin::Test::AssetsPath;
use base qw( Assurer::Plugin::Test );
use File::Spec;
use FindBin;
use File::Basename;
use Data::Dumper;

sub register {
    my ($self) = shift;
    $self->register_tests(qw/ test /);
}

sub test {
    my ($self) = @_;

    my $base_dir =$FindBin::Bin;

    my $assets   = File::Spec->catfile( $base_dir, 'assets' );
    my $kwalitee = File::Spec->catfile( $base_dir, 'assets', 'kwalify' );
    my $discover = File::Spec->catfile( $base_dir, 'assets', 'discover' );
    my $plugins  = File::Spec->catfile( $base_dir, 'assets', 'plugins' );

    my @dirs = ( $assets, $kwalitee, $discover, $plugins );
    foreach my $asset ( @dirs ) {
        if ( -d $asset ) {
            $self->log( error => "OK " . $asset );
        } else {
            $self->log( error => "NOT " . $asset );
        }
    }
}

1;
