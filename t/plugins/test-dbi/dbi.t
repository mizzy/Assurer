use strict;
use t::TestAssurer;

test_plugin_deps;
plan 'no_plan';
run_eval_expected_with_capture;

__END__

=== Test test without dsn
--- input config
global:
  exclude_no_result_test: 1

test:
  - module: DBI
    config:
      dsn:
      user: root

format:
  - module: Text

--- expected
like $warnings, qr/missing dsn/;
ok $context->results->[0]->strap->ok == 0;

=== Test test with dsn
--- input config
global:
  exclude_no_result_test: 1

test:
  - module: DBI
    config: 
      dsn: DBI:Mock:
      user: root

format:
  - module: Text

--- expected
ok $context->results->[0]->strap->ok == 2;
ok $context->results->[0]->strap->details->[0]{ok} == 1;
ok $context->results->[0]->strap->details->[0]{name} eq 'not error ';
ok $context->results->[0]->strap->details->[1]{ok} == 1;
ok $context->results->[0]->strap->details->[1]{name} eq 'ping';
