package Assurer::Plugin::Publish::File;

use strict;
use warnings;
use base qw( Assurer::Plugin::Publish );

sub init {
    my $self = shift;
    die Assurer->context->log(error => 'missing path') unless $self->{config}->{path};
}

sub run {
    my ( $self, $context, $args ) = @_;

    open my $fh, '>', $self->{config}->{path} or die $context->log(error => "open: $!");
    print $fh $args->{format}->content;
    close $fh;
}

1;
__END__

=head1 NAME

Assurer::Plugin::Publish::File - Publish to File

=head1 SYNOPSIS

  - module: File
    config:
      path: /foo/var/test.txt

=head1 DESCRIPTION

Publish to file.

=head1 AUTHOR

Kazuhiro Osawa
