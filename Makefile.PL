use strict;
use inc::Module::Install;

name('Assurer');
all_from('lib/Assurer.pm');

requires 'Class::Accessor::Fast';
requires 'Test::TAP::Model' => 0.08;
requires 'UNIVERSAL::require';
requires 'YAML';
requires 'Kwalify';
requires 'Net::SSH';
requires 'Term::ANSIColor';
requires 'Term::ReadLine';
requires 'Test::WWW::Mechanize';
requires 'Proc::Background';
requires 'Gearman::Client::Async';
requires 'Gearman::Worker';
requires 'Danga::Socket';

build_requires('YAML');

require YAML;
require DirHandle;
require File::Spec;

my $dh = DirHandle->new("deps");
my @plugins;
while (my $f = $dh->read) {
    next unless $f =~ /\.yaml$/;
    my $meta = YAML::LoadFile( File::Spec->catfile("deps", $f) );
    push @plugins, $meta if !$meta->{platform} || $meta->{platform} eq $^O;
}

for my $meta (sort { $b->{default} <=> $a->{default} || $a->{name} cmp $b->{name} } @plugins) {
    features(
        $meta->{name}, [
            -default => $meta->{default},
            map recommends($_ => $meta->{depends}->{$_}), keys %{$meta->{depends} || {}},
        ],
    );
}


auto_include;
auto_install;

WriteAll;
