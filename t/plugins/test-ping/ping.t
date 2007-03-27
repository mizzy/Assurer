use strict;
use t::TestAssurer;

test_plugin_deps;
test_requires_root;
test_requires_network;
plan 'no_plan';
run_eval_expected;

__END__

=== Test test
--- input config
global:
  exclude_no_result_test: 1

test:
  - module: Ping
    config:
      timeout: 9
      protocol: icmp
    role: app

format:
  - module: Text

hosts:
  app:
    - google.com

--- expected
ok $context->results->[0]->strap->seen == 1;
ok $context->results->[0]->strap->details->[0]{ok} == 1;
like $context->results->[0]->strap->details->[0]{name}, qr/ping ok google.com/;