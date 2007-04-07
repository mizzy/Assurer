#!/usr/bin/perl

use strict;
use warnings;

use Config;
use FindBin;
use ExtUtils::MakeMaker;
use File::Basename;
use File::Path;
use YAML;
use Template;

chdir "$FindBin::Bin/..";

my $module = shift @ARGV or die "Usage: plugin-start.pl Plugin::Name\n";
   $module =~ s/-/::/g;

my $file   = "$ENV{HOME}/.assurer-module.yml";
my $config = eval { YAML::LoadFile($file) } || {};

my $save;
$config->{author} ||= do {
    $save++;
    prompt('Your name: ');
};

write_plugin_files($module, $config->{author});

YAML::DumpFile($file, $config) if $save;

sub write_plugin_files {
    my($module, $author) = @_;

    ( my $plugin = $module ) =~ s!::!-!g;
    ( my $path   = $module ) =~ s!::!/!g;
    ( my $base   = $module ) =~ s/::[^:]+$//;

    my ( $type ) = split '::', lc $module;

    my $template = YAML::Load(join '', <DATA>);
    my $vars = {
        module => $module, plugin => $plugin, path => $path,
        author => $author, base   => $base,
    };

    my @files;
    push @files, write_file(
        "lib/Assurer/Plugin/$path.pm",
        $template->{"plugin_$type"},
        $vars,
    );

    push @files, write_file("deps/$plugin.yaml", $template->{deps}, $vars);
    push @files, write_file("t/plugins/$plugin/base.t", $template->{test}, $vars);

    push @files, write_file(
        "assets/kwalify/plugins/$plugin.yaml",
        $template->{kwalify},
        $vars,
    ) unless $type eq 'filter';

    if ( my $vcs = version_control() ) {
        my $ans = prompt("$vcs add newly created files? [Yn]", 'y');
        if ( $ans =~ /[Yy]/ ) {
            system $vcs, 'add', @files;
        }
    }
}

sub write_file {
    my( $path, $template, $vars ) = @_;

    if (-e $path) {
        my $ans = prompt("$path exists. Override? [yN] ", 'n');
        return if $ans !~ /[Yy]/;
    }

    my $dir = File::Basename::dirname($path);
    unless (-e $dir) {
        warn "Creating directory $dir\n";
        File::Path::mkpath($dir, 1, 0777);
    }

    my $tt = Template->new;
    $tt->process(\$template, $vars, \my $content);

    warn "Creating $path\n";
    open my $out, '>', $path or die "$path: $!";
    print $out $content;
    close $out;

    return $path;
}

sub version_control {
    return 'svk' if check_command('svk', 'svk info', qr/Checkout Path/);
    return 'svn' if -e ".svn/entries";
    return;
}

sub check_command {
    my($bin, $command, $re) = @_;
    return unless grep { -e File::Spec->catfile($_, $bin) } split /$Config::Config{path_sep}/, $ENV{PATH};

    my $res = qx($command);
    defined $res && $res =~ $re;
}

__DATA__
plugin_test: |
  package Assurer::Plugin::[% module %];
  use strict;
  use warnings;
  use base qw( Assurer::Plugin::Test );

  sub register {
      my $self = shift;
      $self->register_tests( qw/ ... / );
  }

  1;
  __END__

  =head1 NAME

  Assurer::Plugin::[% module %] -

  =head1 SYNOPSIS

    - module: [% module %]

  =head1 DESCRIPTION

  XXX Write the description for [% module %]

  =head1 CONFIG

  XXX Document configuration variables if any.

  =head1 AUTHOR

  [% author %]

  =head1 SEE ALSO

  L<Assurer>

  =cut

plugin_notify: |
  package Assurer::Plugin::[% module %];
  use strict;
  use warnings;
  use base qw( Assurer::Plugin::Notify );

  sub run {
      my ( $self, $context, $args ) = @_;
      # ...
  }

  1;
  __END__

  =head1 NAME

  Assurer::Plugin::[% module %] -

  =head1 SYNOPSIS

    - module: [% module %]

  =head1 DESCRIPTION

  XXX Write the description for [% module %]

  =head1 CONFIG

  XXX Document configuration variables if any.

  =head1 AUTHOR

  [% author %]

  =head1 SEE ALSO

  L<Assurer>

  =cut

plugin_format: |
  package Assurer::Plugin::[% module %];
  use strict;
  use warnings;
  use base qw( Assurer::Plugin::Format );

  sub run {
      my ( $self, $context, $args ) = @_;
      # ...
  }

  1;
  __END__

  =head1 NAME

  Assurer::Plugin::[% module %] -

  =head1 SYNOPSIS

    - module: [% module %]

  =head1 DESCRIPTION

  XXX Write the description for [% module %]

  =head1 CONFIG

  XXX Document configuration variables if any.

  =head1 AUTHOR

  [% author %]

  =head1 SEE ALSO

  L<Assurer>

  =cut

plugin_publish: |
  package Assurer::Plugin::[% module %];
  use strict;
  use warnings;
  use base qw( Assurer::Plugin::Publish );

  sub run {
      my ( $self, $context, $args ) = @_;
      # ...
  }

  1;
  __END__

  =head1 NAME

  Assurer::Plugin::[% module %] -

  =head1 SYNOPSIS

    - module: [% module %]

  =head1 DESCRIPTION

  XXX Write the description for [% module %]

  =head1 CONFIG

  XXX Document configuration variables if any.

  =head1 AUTHOR

  [% author %]

  =head1 SEE ALSO

  L<Assurer>

  =cut

plugin_filter: |
  package Assurer::Plugin::[% module %];
  use strict;
  use warnings;
  use base qw( Assurer::Plugin::[% base %] );

  sub dispatch {
      my ( $self, $args ) = @_;
      # ...
  }

  1;
  __END__

  =head1 NAME

  Assurer::Plugin::[% module %] -

  =head1 SYNOPSIS

    - module: [% module %]

  =head1 DESCRIPTION

  XXX Write the description for [% module %]

  =head1 CONFIG

  XXX Document configuration variables if any.

  =head1 AUTHOR

  [% author %]

  =head1 SEE ALSO

  L<Assurer>

  =cut

deps: |
  name: [% module %]
  author: [% author %]
  depends:

test: |
  use strict;
  use t::TestAssurer;

  test_plugin_deps;
  plan 'no_plan';
  run_eval_expected;

  __END__

  === Loading [% module %]
  --- input config
  test:
    - module: [% module %]
  --- expected
  ok 1, $block->name;

kwalify: |
  type: map
  mapping:
    host:
      type: str
