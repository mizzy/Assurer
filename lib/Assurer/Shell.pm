package Assurer::Shell;

use strict;
use warnings;
use Net::SSH;
use Term::ReadLine;
use Data::Dumper;
use Term::ANSIColor;
use Storable;

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
        $self->{ context }
            ->log( 'debug' => "You will need Term::ReadLine::Gnu" );
    } else {
        if ( -f $HISTFILE ) {
            $term->ReadHistory( $HISTFILE )
                or $self->{ context }
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
        $self->{ context }
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

    $self->{ parallel }
        = $self->{ context }->{ config }->{ global }->{ parallel }
        || 'Assurer::Parallel::ForkManager';
    $self->{ parallel }->use or die $@;

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
    my ( $self, $input, $hosts ) = @_;

    my $cmd;
    if ( $hosts ) {
        $cmd = $input;
    }
    else {
        ( $hosts, $cmd ) = ( $input =~ m/^!on\s+(.+)\s+do\s+(.+)$/ );
    }

    return print "[WARNING] error in your syntax, see help\n" unless ( $hosts and $cmd );

    my @hosts = split /\s/, $hosts;
    if ( @hosts ) {
        $self->process_command( $cmd, \@hosts );
    }
}

sub process_role {
    my ( $self, $input ) = @_;

    my ( $roles, $cmd ) = ( $input =~ m/^!with\s+(.+)\s+do\s+(.+)$/ );

    return print "[WARNING] error in your syntax, see help\n" unless ( $roles and $cmd );

    my @roles      = split /\s/, $roles;
    my @hosts      = ();
    my @inexistant = ();
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
    my $manager = $self->{ parallel }->new;

    my @hosts = map { $_->{ host } } @{ $self->{ hosts } };
    $manager->run( {
           elems => $hosts || \@hosts,
           callback => sub {
               my $server = shift;
               $self->callback( $server, $cmd );
           },
           num => $self->{ para },
        } );
}

sub process_test {
    my ( $self, $input ) = @_;

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
        my @hosts = split /\s/, $args;
        for my $host ( @hosts ) {
            for my $plugin ( @plugins ) {
                my $clone = Storable::dclone($plugin);
                $clone->{config}->{host} = $host;
                push @jobs, $clone unless $clone->{disable};
            }
        }
    }

    if ( $action and $action eq 'with' ) {
        my @roles = split /\s/, $args;
        for my $role ( @roles ) {
            my $hosts = $self->{config}->{hosts}->{$role};
            print "[WARNING] no such role: $role\n" unless $hosts;
            for my $host ( @$hosts ) {
                for my $plugin ( @plugins ) {
                    my $clone = Storable::dclone($plugin);
                    $clone->{config}->{host} = $host;
                    push @jobs, $clone unless $clone->{disable}
                }
            }
        }
    }
    $self->run_test(@jobs);
}

sub run_test {
    my ( $self, @jobs ) = @_;

    my $context = $self->{context};
    for my $job ( @jobs ) {
        my $class = 'Assurer::Plugin::Test::' . $job->{module};

        $class->use or die $@;
        my $plugin = $class->new({ %$job, context => $self->{context} });

        $plugin->register;
        $plugin->pre_run( $self->{context} );

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

        $self->publish_shell($results);
        ${ $plugin->{test}->{count} } = 0;
        $plugin->post_run;
    }
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

sub publish_shell {
    my ( $self, $results ) = @_;

    for my $result ( split "\n", $results ) {
        if ( $result =~ /^ok/ ) {
            print color 'green';
        } elsif ( $result =~ /^not ok/ ) {
            print color 'red';
        }
        print $result. "\n";
    }

    print color 'reset';
    print "\n";
}

sub callback {
    my ( $self, $server, $cmd ) = @_;

    Net::SSH::sshopen2( $server, *READER, *WRITER, $cmd );
    while ( <READER> ) {
        chomp;
        print "[$server] $_\n";
    }
    close READER;
    close WRITER;
}

sub help {
    my ( $self ) = @_;
    my $help = <<HELP;
 To quit, just type quit, exit, or press ctrl-D.
 This shell is still experimental.

 execute a command on all servers, just type it directly, like:

assurer> ping

 To execute a command on a specific set of servers, specify an 'on' clause.
 Note that if you specify more than one host name, they must be 
 space-delimited.

assurer> on app1.foo.com app2.foo.com do ping

 To execute a command on all servers matching a set of roles:

assurer> with web db do ping

HELP
    print $help;
}

1;
