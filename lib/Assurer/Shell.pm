package Assurer::Shell;

use strict;
use warnings;
use Net::SSH;
use Term::ReadLine;
use Data::Dumper;

sub new {
    my ( $class, $args ) = @_;
    return bless { %$args }, $class;
}

sub run_loop {
    my $self = shift;

    my $term = Term::ReadLine->new('Assurer');

    my $HISTFILE = ($ENV{HOME} || ( ( getpwuid($<) )[7] ) ) . '/.assurer_shell_history';
    my $HISTSIZE = 256;

	# this won't work with Term::ReadLine::Perl
	# If there is Term::ReadLine::Gnu, be sure to do : export "PERL_RL=Gnu o=0"
	eval { $term->stifle_history($HISTSIZE);};

	if (@!){
		$self->{context}->log('debug' => "You will need Term::ReadLine::Gnu");
	}else{
    	if (-f $HISTFILE) {
        	$term->ReadHistory($HISTFILE) or $self->{context}->log('warn' => "cannot read history file: $!");
    	}
	}

    while ( defined( my $line = $term->readline('assurer> ') )) {
        next if $line =~ /^\s*$/;
        $self->catch_run($line);
    }

    print "\n";

	eval {$term->WriteHistory($HISTFILE);};
	if (@!){
		$self->{context}->log('debug' => "perlsh: cannot write history file: $!");
	}
}

sub catch_run {
    my ($self, $cmd) = @_;

    $self->{parallel} = $self->{context}->{config}->{global}->{parallel}
        || 'Assurer::Parallel::ForkManager';
    $self->{parallel}->use or die $@;

	if ($cmd =~ /^on/){
		if ($cmd =~ /^on\s(.*)\sdo\s(.*)$/){
			$self->process_host($1, $2);
		}else{
			print "[WARNING] error in your syntax, see help\n";
		}
	}elsif($cmd =~ /^with/){
		if ($cmd =~ /^with\s(.*)\sdo\s(.*)$/){
			$self->process_role($1, $2);
		}else{
			print "[WARNING] error in your syntax, see help\n";
		}
	}elsif($cmd =~ /^help/){
		$self->help();
	}elsif($cmd =~ /^(quit|exit)/){
		print "bye bye\n";
		exit;
	}else{
		$self->process_command($cmd);
	}
}

sub process_host {
	my ($self, $hosts, $cmd) = @_;

	my @hosts = split /\s/, $hosts;

	if (@hosts){
            $self->process_command($cmd, \@hosts);
	}
}

sub process_role {
    my ($self, $roles, $cmd) = @_;

    my @roles = split /\s/, $roles;
    my @hosts = ();
    my @inexistant = ();
    foreach my $role (@roles){
        if ( !grep { $_->{role} eq $role }  @{ $self->{hosts} } ){
            push (@inexistant, $role);
            next;
        }
        foreach my $host ( grep { $_->{role} eq $role } @{ $self->{hosts} } ){
            push @hosts, $host->{host};
        }
    }
    if (@inexistant){
        print "[WARNING] inexisting role(s) for " . join(' ', @inexistant) . "\n";
    }
    $self->process_command($cmd, \@hosts);
}

sub process_command {
    my ($self, $cmd, $hosts) = @_;
    my $manager = $self->{parallel}->new;

    my @hosts = map { $_->{host} } @{ $self->{hosts} };
    $manager->run({
        elems => $hosts || \@hosts,
        callback => sub {
            my $server = shift;
            $self->callback($server, $cmd);
        },
        num => $self->{para},
    });
}

sub callback {
    my ( $self, $server, $cmd ) = @_;

    Net::SSH::sshopen2( $server, *READER, *WRITER, $cmd );
    while (<READER>) {
        chomp;
        print "[$server] $_\n";
    }
    close READER;
    close WRITER;
}

sub help {
    my ($self) = @_;
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
