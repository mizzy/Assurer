package Assurer::Plugin::Test::Log;
use base qw( Assurer::Plugin::Test );

sub register {
    my($self, $context) = @_;
    $self->log(error => "this is error");
    $self->log(info  => "this is info");
    $self->log(warn  => "this is warn");
    $self->log(debug => "this is debug");
}

1;

__END__