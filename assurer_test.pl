#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use File::Spec;
use Getopt::Long;
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use Assurer;
use YAML;
use MIME::Base64;
use UNIVERSAL::require;

GetOptions(
    '--config=s'  => \my $config,
    '--context=s' => \my $context,
    '--version'   => \my $version,
);

$config  = Load( MIME::Base64::decode($config) );
$context = Load( MIME::Base64::decode($context) );

my $class = 'Assurer::Plugin::Test::' . $config->{module};

$class->use or die $@;
my $plugin = $class->new({ config => $config, context => $context });
$plugin->pre_run($context);
$plugin->post_run;
