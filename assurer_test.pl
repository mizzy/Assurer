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
my $plugin = $class->new({ %$config, context => $context });

$plugin->register;
$plugin->pre_run($context);

my $retry    = $plugin->conf->{retry}    || $context->conf->{retry}    || 3;
my $interval = $plugin->conf->{interval} || $context->conf->{interval} || 3;

my $results;
for my $test ( @{ $plugin->tests } ) {
    my $retry_count = 0;
    for ( 1 .. $retry ) {
        my $result = $plugin->$test($context);
        next unless $result;
        if ( $result =~ /^not ok/ ) {
            $retry_count++;
            if ( $retry_count < $retry ) {
                $plugin->{test}->decr_count;
                sleep $interval;
            }
            else {
                $results .= "$result\n";
            }
        }
        else {
            $results .= "$result\n";
            last;
        }
    }
}

print $results;
$plugin->post_run;
