#!/usr/bin/perl

use strict;
use warnings;

use Gearman::Worker;
use Storable qw(thaw);
use Getopt::Long;
use File::Spec;
use FindBin;

use lib (
    File::Spec->catdir($FindBin::Bin, '..', 'lib'),
    File::Spec->catdir($FindBin::Bin, '..', 't', 'core'),
);

use Assurer;
use UNIVERSAL::require;

GetOptions ( "job_servers=s" => \my @job_servers );
@job_servers = split( /,/, join(',', @job_servers) );

push @job_servers, 'localhost' unless @job_servers;

my $worker = Gearman::Worker->new;

$worker->job_servers(@job_servers);

$worker->register_function(
    test => \&test,
);

$worker->work while 1;

sub test {
    my $job = shift;
    my ( $config, $context ) = @{ thaw($job->arg) };

    my $class = 'Assurer::Plugin::Test::' . $config->{module};

    $class->use or die $@;
    my $plugin = $class->new({ %$config, context => $context });

    $plugin->register;
    $plugin->pre_run($context);

    my $retry    = $plugin->conf->{retry}    || $context->conf->{retry}    || 3;
    my $interval = $plugin->conf->{interval} || $context->conf->{interval} || 3;

    $retry = 1 if ref $plugin eq 'Assurer::Plugin::Test::WWW::Mechanize';
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

    $plugin->{test}->reset_count;

    return $results;
}



