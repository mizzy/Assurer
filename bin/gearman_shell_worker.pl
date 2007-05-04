#!/usr/bin/perl

use strict;
use warnings;

use Gearman::Worker;
use Storable qw(thaw);
use Getopt::Long;
use File::Spec;
use FindBin;
use Net::SSH qw( sshopen2 );

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
    shell => \&shell,
);

$worker->work while 1;

sub shell {
    my $job = shift;
    my ( $host, $cmd, $user ) = @{ thaw($job->arg) };

    $host = join '@', $user, $host if defined $user;
    Net::SSH::sshopen2( $host, *READER, *WRITER, $cmd );
    $host =~ s/.*@//;

    my $res;
    while ( <READER> ) {
        $res .= "[$host] $_";
    }
    close READER;
    close WRITER;

    return $res;
}
