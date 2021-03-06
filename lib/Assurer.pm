package Assurer;

use 5.8.1;
use warnings;
use strict;
use Carp;

our $VERSION = '0.01';

use base qw( Class::Accessor::Fast );
use Assurer::ConfigLoader;
use Assurer::Dispatch;
use UNIVERSAL::require;
use Encode;
use File::Spec;
use Assurer::Shell;
use Assurer::ProcHandler;

__PACKAGE__->mk_accessors( qw/ test / );

my $context;
sub context { $context }
sub set_context {
    my ($class, $c) = @_;
    $context = $c;
}

sub bootstrap {
    my ( $class, $opts ) = @_;

    my $self = $class->new($opts);

    if ( $opts->{shell} ) {
        $self->shell($opts);
    }
    elsif ( $opts->{discover} ){
        $self->discover($opts);
    }
    else {
        $self->run;
    }

    return $self;
}

sub new {
    my ( $class, $opts ) = @_;

    my $self = bless { %$opts }, $class;

    # basedir, for test and configloader
    my @path = File::Spec->splitdir($FindBin::Bin);
    my $base_dir = File::Spec->catfile(@path);
    while (defined(my $dir = pop @path)) {
        if ($dir eq 't') {
            $base_dir = File::Spec->catfile(@path);
            last;
        }
    }
    $self->{base_dir} = $base_dir;

    my $config_loader = Assurer::ConfigLoader->new($self->{base_dir});
    $self->{config} = $config_loader->load($opts->{config}, $self);

    my $global = $self->{config}->{global};
    $global->{host} ||= $opts->{host};
    $global->{para} ||= $opts->{para} || 5;

    my $gearman = $global->{gearman};

    $global->{gearman}->{start_workers} = 1
        unless defined $global->{gearman}->{start_workers};

    $global->{gearman}->{start_gearmand} = 1
        unless defined $global->{gearman}->{start_gearmand};

    Assurer->set_context($self);

    $self->conf->{log} ||= { level => 'debug' };

    if ( eval { require Term::Encoding } ) {
        $global->{log}->{encoding} ||= Term::Encoding::get_encoding();
    }

    if ( my $hosts = $self->{config}->{hosts} ) {
        $self->{hosts} = [];
        if ( ref $hosts eq 'HASH' ) {
            for my $role ( keys %$hosts ) {
                for my $host ( @{ $hosts->{$role} } ) {
                    push @{ $self->{hosts} }, { role => $role, host => $host };
                }
            }
        }
        else {
            for my $host ( @$hosts ) {
                push @{ $self->{hosts} }, { role => undef, host => $host };
            }
        }
    }

    $self->{proc_handler} = Assurer::ProcHandler->new;

    return $self;
}

sub get_hosts_by_role {
    my ($self, $search_role) = @_;

    my @hosts;
    for my $host ( @{ $self->{hosts} } ) {
        if ( my $role = $search_role ) {
            push @hosts, $host if $host->{role} eq $role;
        }
        else {
            push @hosts, $host;
        }
    }
    return @hosts;
}

sub shell {
    my ( $self, $opts ) = @_;

    my $proc_handler = $self->{proc_handler};
    my $gearman      = $self->conf->{gearman};

    $proc_handler->start_gearmand      if $gearman->{start_gearmand};
    $proc_handler->start_test_workers  if $gearman->{start_workers};
    $proc_handler->start_shell_workers if $gearman->{start_workers};

    my @hosts = $self->get_hosts_by_role( $opts->{role} );
    my $shell = Assurer::Shell->new({
        context => $self,
        config  => $self->{config},
        hosts   => \@hosts,
        user    => $opts->{user},
        para    => $opts->{para} || $self->conf->{para} || 5,
    });

    $shell->run_loop;
}

sub discover {
	my ($self, $opts) = @_;

        Assurer::Discover->require;

	my @hosts = $self->get_hosts_by_role( $opts->{role} );
	my $discover = Assurer::Discover->new({
            context => $self,
            config  => $self->{config},
            hosts   => \@hosts,
            para    => $opts->{para},
	});
	$discover->run_discover;
}

sub run {
    my ( $self, $args ) = @_;
    $args ||= {};

    $self->load_plugins;

    $self->{proc_handler}->start_gearmand if $self->conf->{gearman}->{start_gearmand};
    $self->{proc_handler}->start_test_workers if $self->conf->{gearman}->{start_workers};

    my $dispatch = Assurer::Dispatch->new({
        context => $context,
    });
    $dispatch->run;

    ### TODO: Insert global result filter process.

    $self->run_hook('format', { results => $context->results });

    $self->run_hook('notify', { results => $context->results });

    ### ToDO: Insert global format filter process.

    for my $format ( @{ $self->formats || [] } ) {
        $self->run_hook('publish', { format => $format });
    }
}

sub run_hook {
    my ( $self, $hook, $args ) = @_;
    $args ||= {};

    for my $plugin ( @{ $self->{hooks}->{$hook} || [] } ) {
        if ( $hook eq 'format' or $hook eq 'notify' ) {
            if ( $plugin->filter ) {
                my @results;
                for ( @{ $args->{results} } ) {
                    my $result = $_->clone;
                    $result = $plugin->filter->dispatch($result);
                    next if ( !@{ $result->strap->details } and $self->conf->{exclude_no_result_test} );
                    push @results, $result;
                }
                $args->{results} = \@results;
            }
        }
        elsif ( $hook eq 'publish' ) {
            if ( $plugin->filter ) {
                next unless $plugin->filter->dispatch($args);
            }
        }

        $plugin->pre_run($context, $args);
        $plugin->post_run($context, $args) if $plugin->can('post_run');
    }
}

sub load_plugins {
    my $self = shift;

    for my $hook ( qw/format notify publish/ ) {
        for my $plugin ( @{ $self->{config}->{$hook} || [] } ) {
            my $class = "Assurer::Plugin::" . ucfirst $hook . "::$plugin->{module}";
            next if $plugin->{disable};
            $class->use or die $@;
            $plugin->{config} ||= {};

            my $instance = $class->new($plugin);

            if ( my $filter = $plugin->{filter} ) {
                if ( $hook eq 'format' or $hook eq 'notify' ) {
                    $filter->{module} = "Result::$filter->{module}";
                }
                else {
                    $filter->{module} = "Format::$filter->{module}";
                }
                my $class = "Assurer::Plugin::Filter::$filter->{module}";
                $class->use or die $@;
                $instance->filter( $class->new($filter) );
            }

            push @{ $self->{hooks}->{$hook} }, $instance;
        }
    }
}

sub log {
    my ( $self, $level, $msg, %opts ) = @_;

    return unless $self->should_log($level);

    my $caller = $opts{caller};

    unless ($caller) {
        my $i = 0;
        while (my $c = caller($i++)) {
            last if $c !~ /Plugin/;
            $caller = $c;
        }
        $caller ||= caller(0);
    }

    if ($self->conf->{log}->{encoding}) {
        $msg = Encode::decode_utf8($msg) unless utf8::is_utf8($msg);
        $msg = Encode::encode($self->conf->{log}->{encoding}, $msg);
    }

    warn "$caller [$level] $msg\n";
}

sub add_result {
    my $self = shift;
    push @{ $self->{results} }, shift;
}

sub results {
    return shift->{results};
}

sub add_format {
    my ( $self, $format ) = @_;
    push @{ $self->{formats} }, $format if defined $format->content;
}

sub formats {
   return shift->{formats};
}

sub conf {
    shift->{config}->{global};
}

sub hosts {
    shift->{hosts} || [];
}

my %levels = (
    debug => 0,
    warn  => 1,
    info  => 2,
    error => 3,
);

sub should_log {
    my($self, $level) = @_;
    $levels{$level} >= $levels{$self->conf->{log}->{level}};
}

sub error {
    my( $self, $msg ) = @_;
    my( $caller, $filename, $line ) = caller(0);
    chomp $msg;
    die "$caller [fatal] $msg at line $line\n";
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Assurer - [One line description of module's purpose here]


=head1 VERSION

This document describes Assurer version 0.0.1


=head1 SYNOPSIS

    use Assurer;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
  
=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Assurer requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-assurer@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Gosuke Miyashita  C<< <gosukenator@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Gosuke Miyashita C<< <gosukenator@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
