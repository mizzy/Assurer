use strict;
use t::TestAssurer;

plan 'no_plan';
run_eval_expected_with_capture;

__END__

=== log level is debug
--- input config
global:
  log:
    level: debug

test:
  - module: Log
    name: Dumb Test

--- expected
like $warnings, qr/error/;
like $warnings, qr/info/;
like $warnings, qr/warn/;
like $warnings, qr/debug/;

=== info log level
--- input config
global:
  log:
    level: info

test:
  - module: Log
    name: Dumb Test

--- expected
like $warnings, qr/error/;
like $warnings, qr/info/;
unlike $warnings, qr/warn/;
unlike $warnings, qr/debug/;
