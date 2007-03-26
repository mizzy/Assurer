#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use File::Spec;
use Getopt::Long;

use lib File::Spec->catdir($FindBin::Bin, 'lib');
use Assurer;

my $config = File::Spec->catfile($FindBin::Bin, 'config.yaml');
GetOptions(
    '--config=s' => \$config,
    '--host=s'   => \my $host,
    '--version'  => \my $version,
    '--shell'    => \my $shell,
    '--role=s'   => \my $role,
    '--para=s'   => \my $para,
    '--discover' => \my $discover,
    '--user=s'   => \my $user,
);

Getopt::Long::Configure('bundling');

if ($version) {
    print "Assurer version $Assurer::VERSION\n";
    exit;
}

die 'You should be root for --discover' if $discover and $< > 0;

Assurer->bootstrap({
    config => $config,
    host   => $host,
    shell  => $shell,
    role   => $role,
    para   => $para,
    discover => $discover,
    user   => $user,
});

exit;
