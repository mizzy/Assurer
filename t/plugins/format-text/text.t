use strict;
use t::TestAssurer;

test_plugin_deps;
test_requires_network;
plan 'no_plan';
run_eval_expected;

__END__

=== Test format html
--- input config
global:
  exclude_no_result_test: 1

test:
  - module: HTTP
    name: HTTP Test
    config:
      scheme: http
    role: http

format:
  - module: Text  

hosts:
  http:
    - google.com:80

--- expected
ok $context->results->[0]->strap->ok == 1;
