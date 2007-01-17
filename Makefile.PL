use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Assurer',
    AUTHOR              => 'Gosuke Miyashita <gosukenator@gmail.com>',
    VERSION_FROM        => 'lib/Assurer.pm',
    ABSTRACT_FROM       => 'lib/Assurer.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Assurer-*' },
);
