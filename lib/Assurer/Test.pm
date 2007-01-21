package Assurer::Test;

use strict;
use warnings;

use Test::Builder;
use Test::TAP::Model;

require Exporter;
use vars qw( @ISA @EXPORT $AUTOLOAD );

@ISA = qw( Exporter );
@EXPORT = qw(
                ok is_eq is_num isnt_eq isnt_num
                like unlike maybe_regex cmp_ok
                BAIL_OUT skip todo_skip
        );

my $test = Test::Builder->new;
$test->plan('no_plan');

sub new {
    my $class = shift;
    my $self = { };
    bless $self, $class;
    return $self;
}

sub init {

}

sub AUTOLOAD {
     my $func   = $AUTOLOAD;
     return if $func =~ /::DESTROY$/;

     my ($class,$method) = $func =~ /(.+)::(.+)$/;

     my $code   = sub {
         no strict 'refs';
         $test->$method(@_);
     };

     no strict 'refs';
     *{$func} = $code;
     goto &$code;
}

1;