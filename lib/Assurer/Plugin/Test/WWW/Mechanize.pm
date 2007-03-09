package Assurer::Plugin::Test::WWW::Mechanize;

use strict;
use warnings;
use Assurer::Test::WWW::Mechanize;
use DirHandle;
use File::Spec;
use base qw( Assurer::Plugin::Test );

sub register {
    my $self = shift;
    $self->register_tests( qw/ load_plugins / );
}

sub load_plugins {
    my $self = shift;
    my $context = $self->{context};

    my $dir = $self->assets_dir;
    my $dh = DirHandle->new($dir) or $context->error("$dir: $!");
    for my $file (grep -f $_->[0] && $_->[0] =~ /\.(?:pl|yaml)$/,
                  map [ File::Spec->catfile($dir, $_), $_ ], sort $dh->read) {
        $self->load_plugin(@$file);
    }
}

sub load_plugin {
    my ( $self, $file, $base ) = @_;

    $self->{context}->log(debug => "loading $file");

    my $load_method = $file =~ /\.pl$/ ? 'load_plugin_perl' : 'load_plugin_yaml';
    push @{ $self->{plugins} }, $self->$load_method($file, $base);
}

sub load_plugin_perl {
    my($self, $file, $base) = @_;

    open my $fh, '<', $file or $self->{context}->error("$file: $!");

    my $code = do { local $/; <$fh> };
    close $fh;

    $code = join "\n",
        (
            'my $conf = $self->conf;',
            'my $host = $conf->{host} || $self->{context}->conf->{host};',
            'my $mech = Assurer::Test::WWW::Mechanize->new;',
            $code,
        );

    eval $code;
    $self->{context}->error($@) if $@;
}

1;

__END__

=head1 NAME

Assurer::Plugin::Test::WWW::Mechanize - Test using Test::WWW::Mechanize

=head1 SYNOPSIS

  - module: WWW::Mechanize
    role: web

=head1 DESCRIPTION

This plugin executes tests using Test::WWW::Mechanize.

For this plugin, you should create .pl file.
Please see assets/plugins/Test-WWW-Mechanize/example.pl.

=head1 AUTHOR

Gosuke Miyashita

