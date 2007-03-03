package Assurer::Plugin::Publish::Mail;

use strict;
use warnings;
use base qw( Assurer::Plugin::Publish );
use MIME::Lite;

sub init {
    my $self = shift;
}

sub run {
    my ( $self, $context, $args ) = @_;

    my $conf = $self->conf;
    my $msg = MIME::Lite->new(
        From    => $conf->{from},
        To      => $conf->{to},
        Subject => $conf->{subject},
        Type    => $args->{format}->type,
        Data    => $args->{format}->content,
    );

    $msg->send;
    $context->log(info => "Sending $conf->{subject} to $conf->{to}");
}

1;
__END__

=head1 NAME

Assurer::Plugin::Publish::Mail - Send result by mail

=head1 SYNOPSIS

  - module: Mail
    config:
      subject: Test results from Assurer
      to: someone@example.com, another@example.com
      from: root@example.com

=head1 DESCRIPTION

Send reslts by mail.

=head1 AUTHOR

Franck Cuny
Gosuke Miyashita
