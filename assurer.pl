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
);

Getopt::Long::Configure('bundling');

if ($version) {
    print "Assurer version $Assurer::VERSION\n";
    exit;
}

Assurer->bootstrap({
    config => $config,
    host   => $host,
});

exit;
