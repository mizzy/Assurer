package Assurer::Discover;

use strict;
use warnings;
use Net::SSH;
use Data::Dumper;
use Nmap::Scanner;
use YAML;

my $assets_dir = File::Spec->catfile( $FindBin::Bin, 'assets', 'discover' );

sub new {
    my ( $class, $args ) = @_;
    return bless { %$args }, $class;
}

sub run_discover {
    my ( $self ) = @_;

    # find ports
    $self->execute();

    # generate a config file
    $self->create_config();
}

sub process {
    my ( $self, $services, $host ) = @_;

    foreach my $service ( @{ $services } ) {
        my $process_yaml = File::Spec->catfile( $assets_dir, "$service.yaml" );
        if ( -f $process_yaml ) {
            # we load the configuration if not already loaded
            # ne pas utiliser le nom du module
            my $yaml_conf = YAML::LoadFile( $process_yaml );
            if ( !defined $self->{module}->{ $$yaml_conf[0]->{module} } ) {
                $self->{modules}->{ $$yaml_conf[0]->{module} } = $$yaml_conf[0];
            }
            if ( $$yaml_conf[0]->{role} ) {
                # we push this host in the role for this process name
                if ( ! grep { $host eq $_ } @{ $self->{roles}->{ $$yaml_conf[0]->{role} } } ){
                    push( @{ $self->{roles}->{ $$yaml_conf[0]->{role} } }, $host );
                }
            }
        }
    }
}

sub execute {
    my ( $self ) = @_;
    foreach my $server ( @{ $self->{ hosts } } ) {
        my $scanner = new Nmap::Scanner;
        $scanner->tcp_syn_scan();
        $scanner->max_rtt_timeout(200);
        $scanner->add_target($server->{host});

        my $results = $scanner->scan();

        my $hosts = $results->get_host_list();
        while ( my $host = $hosts->get_next() ) {
            my $ports = $host->get_port_list();
            my @services;
            while ( my $port = $ports->get_next() ) {
                push @services, $port->service->name;
            }
            $self->process(\@services, $server->{host});
        }
    }
}

sub create_config {
    my ($self) = @_;

    # delete both hosts and test from the current files
    delete $self->{config}->{hosts};
    delete $self->{config}->{test};

    # created in new in Assurer.pm
    delete $self->{config}->{global}->{host};

    # we set the new hosts
    $self->{config}->{hosts} = $self->{roles};

    # generate config for each module
    foreach my $module ( keys %{ $self->{modules} } ) {
        my $ynode = YAML::Node->new({}, 'test/'.$module);
        $ynode = $self->{modules}->{$module};
        push @{ $self->{config}->{test} }, $ynode;
    }

    print print Dump($self->{config});
}

1;

__END__
