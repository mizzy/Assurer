package Assurer::Shell;

use strict;
use warnings;
use Net::SSH;
use Term::ReadLine;
use Data::Dumper;
use Term::ANSIColor;
use Storable qw( freeze );
use Gearman::Client::Async;

sub new {
    my ( $class, $args ) = @_;
    return bless { %$args }, $class;
}

sub run_loop {
    my $self = shift;

    my $term = Term::ReadLine->new( 'Assurer' );

    my $HISTFILE = ( $ENV{ HOME } || ( ( getpwuid( $< ) )[ 7 ] ) )
        . '/.assurer_shell_history';
    my $HISTSIZE = 256;

   # this won't work with Term::ReadLine::Perl
   # If there is Term::ReadLine::Gnu, be sure to do : export "PERL_RL=Gnu o=0"
    eval { $term->stifle_history( $HISTSIZE ); };

    if ( @! ) {
        $self->{context}
            ->log( 'debug' => "You will need Term::ReadLine::Gnu" );
    } else {
        if ( -f $HISTFILE ) {
            $term->ReadHistory( $HISTFILE )
                or $self->{context}
                ->log( 'warn' => "cannot read history file: $!" );
        }
    }

    while ( defined( my $line = $term->readline( 'assurer> ' ) ) ) {
        next if $line =~ /^\s*$/;
        $self->catch_run( $line );
    }

    print "\n";

    eval { $term->WriteHistory( $HISTFILE ); };
    if ( @! ) {
        $self->{context}
            ->log( 'debug' => "perlsh: cannot write history file: $!" );
    }
}

my %cmd_map = (
    on   => 'process_host',
    with => 'process_role',
    test => 'process_test',
);

sub catch_run {
    my ( $self, $cmd ) = @_;

    if ( $cmd =~ /^!([^\s]+)/ ) {
        my $method = $cmd_map{$1};
        $self->$method($cmd);
    }
    elsif ( $cmd =~ /^help/ ) {
        $self->help();
    }
    elsif ( $cmd =~ /^(quit|exit)/ ) {
        print "bye bye\n";
        exit;
    }
    else {
        $self->process_command( $cmd );
    }
}

sub process_host {
    my ( $self, $input ) = @_;

    my ( $hosts, $cmd ) = ( $input =~ m/^!on\s+(.+)\s+do\s+(.+)$/ );

    return print "[WARNING] error in your syntax, see help\n" unless ( $hosts and $cmd );

    my @hosts;
    if ( $hosts =~ m!/(.*)/! ) {
        push @hosts, grep { $_ =~ /$1/ } map { $_->{host} } @{ $self->{hosts} };
    }
    else {
        @hosts = split /\s/, $hosts;
    }

    if ( @hosts ) {
        $self->process_command( $cmd, \@hosts );
    }
}

sub process_role {
    my ( $self, $input ) = @_;

    my ( $roles, $cmd ) = ( $input =~ m/^!with\s+(.+)\s+do\s+(.+)$/ );

    return print "[WARNING] error in your syntax, see help\n" unless ( $roles and $cmd );

    my @roles;
    if ( $roles =~ m!/(.*)/! ) {
        push @roles, grep { $_ =~ /$1/ } keys %{ Assurer->context->{config}->{hosts} };
    }
    else {
        @roles = split /\s/, $roles;
    }

    my @hosts;
    my @inexistant;
    foreach my $role ( @roles ) {
        if ( !grep { $_->{ role } eq $role } @{ $self->{ hosts } } ) {
            push( @inexistant, $role );
            next;
        }
        foreach
            my $host ( grep { $_->{ role } eq $role } @{ $self->{ hosts } } )
        {
            push @hosts, $host->{ host };
        }
    }
    if ( @inexistant ) {
        print "[WARNING] inexisting role(s) for "
            . join( ' ', @inexistant ) . "\n";
    }
    $self->process_command( $cmd, \@hosts );
}

sub process_command {
    my ( $self, $cmd, $hosts ) = @_;

    my @hosts = map { $_->{host} } @{ $self->{hosts} };

    my $client = Gearman::Client::Async->new( job_servers => ['127.0.0.1'] );

    my ( @tasks, $adder );
    my $i = 0;
    $adder = sub {
        my $host = $hosts[$i];
        my $task = Gearman::Task->new(
            'shell',
            \( freeze([ $host, $cmd, $self->{user} ]) ),
            +{
                on_complete => sub { print ${$_[0]}; }
            },
        );
        $client->add_task($task);
        push @tasks, $task;

        $i++;

        if ( $i < @hosts ) {
            Danga::Socket->AddTimer( 0 => $adder );
        }
    };
    Danga::Socket->AddTimer( 0 => $adder );

    Danga::Socket->SetPostLoopCallback(
        sub { scalar(grep { ! $_->is_finished } @tasks) }
    );

    Danga::Socket->EventLoop;
}

sub process_test {
    my ( $self, $input ) = @_;

    my $context = $self->{context};

    my ( $test, $action, $args ) = ( $input =~ m/^!test\s+(\w+)\s?(on|with)?\s?(.*)?$/ );

    my @plugins = grep { $_->{module} eq $test } @{ $self->{config}->{test} };

    return print "[WARNING] no such test plugin config: $test\n" unless @plugins;

    my @jobs;
    if ( !$action ) {
        for ( @plugins ) {
            push @jobs, $self->set_host($_);
        }
    }

    if ( $action and $action eq 'on' ) {
        my @hosts;
        if ( $args =~ m!/(.*)/! ) {
            push @hosts, grep { $_ =~ /$1/ } map { $_->{host} } @{ $self->{hosts} };
        }
        else {
            @hosts = split /\s/, $args;
        }

        for my $host ( @hosts ) {
            for my $plugin ( @plugins ) {
                my $clone = Storable::dclone($plugin);
                $clone->{config}->{host} = $host;
                push @jobs, $clone unless $clone->{disable};
            }
        }
    }

    if ( $action and $action eq 'with' ) {
        my @roles;
        if ( $args =~ m!/(.*)/! ) {
            push @roles, grep { $_ =~ /$1/ } keys %{ Assurer->context->{config}->{hosts} };
        }
        else {
            @roles = split /\s/, $args;
        }

        for my $role ( @roles ) {
            my $hosts = $self->{config}->{hosts}->{$role};

            unless ( $hosts ) {
                print "[WARNING] no such role: $role\n";
                return;
            }

            for my $host ( @$hosts ) {
                for my $plugin ( @plugins ) {
                    my $clone = Storable::dclone($plugin);
                    $clone->{config}->{host} = $host;
                    push @jobs, $clone unless $clone->{disable}
                }
            }
        }
    }

    my $dispatcher = Assurer::Dispatch->new({ context => $context });
    $dispatcher->run_tests(@jobs);

    require Assurer::Plugin::Format::Text;
    require Assurer::Plugin::Publish::Term;

    push @{ $context->{hooks}->{format} }, Assurer::Plugin::Format::Text->new({})
        unless $context->{hooks}->{format};
    push @{ $context->{hooks}->{publish} }, Assurer::Plugin::Publish::Term->new({})
        unless $context->{hooks}->{publish};

    $context->run_hook('format', { results => $context->results });

    for my $format ( @{ $context->formats || [] } ) {
        $context->run_hook('publish', { format => $format });
    }

    $context->{formats} = [];
    $context->{results} = [];
}

sub set_host {
    my ( $self, $plugin ) = @_;

    my $hosts = $self->{context}->hosts;
    my @jobs;
    if ( @$hosts and !defined $plugin->{config}->{host} and !defined $plugin->{config}->{uri} ) {
        for my $host ( @$hosts ) {
            next if ( $plugin->{role} and ( !defined $host->{role} or $host->{role} ne $plugin->{role} ) );
            my $clone = Storable::dclone($plugin);
            $clone->{config}->{host} = $host->{host};
            push @jobs, $clone unless $clone->{disable};
        }
    }
    else {
        push @jobs, $plugin unless $plugin->{disable};
    }

    return @jobs;
}

sub help {
    my ( $self ) = @_;

    my $available_test = join ' ', map { $_->{module} } @{$self->{context}->{config}->{test}};

    my $help = <<HELP;
 To quit, just type quit, exit, or press ctrl-D.
 This shell is still experimental.

 execute a command on all servers, just type it directly, like:

assurer> ping

 To execute a command on a specific set of servers, specify an 'on' clause.
 Note that if you specify more than one host name, they must be 
 space-delimited.

assurer> !on app1.foo.com app2.foo.com do ping
assurer> !on /.*\.foo.com/ do ping

 To execute a command on all servers matching a set of roles:

assurer> !with web db do ping
assurer> !with /web|mail/ do ping

 You can execute tests to, like this:

assurer> !test SSH on app1.foo.com
assurer> !test SSH on /.*\.foo.com/
assurer> !test SSH with web
assurer> !test SSH with /web|mail/

 Available tests are : $available_test

HELP

	print $help;

}

1;
