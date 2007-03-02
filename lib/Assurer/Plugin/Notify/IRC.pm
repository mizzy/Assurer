package Assurer::Plugin::Notify::IRC;

use strict;
use warnings;
use base qw( Assurer::Plugin::Notify );

use Encode;
use POE::Component::IKC::ClientLite;

sub run {
    my ( $self, $context, $args ) = @_;

    my $host = $self->conf->{daemon_host} || 'localhost';
    my $port = $self->conf->{daemon_port} || 9999;

    $self->{remote} = POE::Component::IKC::ClientLite::create_ikc_client(
        port    => $port,
        ip      => $host,
        name    => 'Assurer' . $$,
        timeout => 5,
    );

    unless ($self->{remote}) {
        my $msg = q{unable to connect to assurer-ircbot process on }
            . "$host:$port"
            . q{, if you're not running assurer-ircbot, you should be able }
            . q{to start it with the same Notify::IRC config you passed to }
            . q{assurer. };
        $context->log( error => $msg );
        return;
    }

    my $results = $args->{results};

    for my $result ( @$results ) {
        $context->log(info => "Notifying " . $result->name . " to IRC");
        my $cnt = 1;
        for my $detail ( @{ $result->strap->details } ) {
            my $line = $detail->{ok} ? "ok $cnt - " : "not ok $cnt - ";
            $line   .= $detail->{name};
            $self->{remote}->post( 'notify_irc/update', $line );
            $cnt++;
        }
    }
}

1;

__END__

=head1 NAME

Assurer::Plugin::Notify::IRC - Notify test results to IRC

=head1 SYNOPSIS

  - module: Notify::IRC
    config:
      daemon_port: 9999
      nickname: assurerbot
      server_host: chat.freenode.net
      server_port: 6667
      server_channels:
        - #assurer-test
      charset: iso-2022-jp
      announce: notice

=head1 DESCRIPTION

Notify test results to IRC.

=head1 SETUP

In order to make Notify::IRC run, you need to run I<plagger-ircbot>
script first, before running the assuer main process.
I<plagger-ircbot> is icluded in L<Plagger>.

  % ./bin/plagger-ircbot -c irc.yaml &

=head1 AUTHOR

Gosuke Miyashita

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Notify::IRC>, L<POE::Component::IRC>

=cut
