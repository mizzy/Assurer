use strict;
use t::TestAssurer;

test_plugin_deps;
test_requires_network;
plan 'no_plan';
run_eval_expected;

__END__

=== Test basic http test
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
    - http://www.google.com:80

--- expected
ok $context->results->[0]->strap->seen == 1;
ok $context->results->[0]->strap->details->[0]{ok} == 1;
ok $context->results->[0]->strap->details->[0]{name} eq 'HTTP status code of http://www.google.com:80 is 200';

=== Test test http content
--- input config
global:
  exclude_no_result_test: 1

test:
  - module: HTTP
    name: HTTP Test
    config:
      scheme: http
      content: Google
    role: http

format:
  - module: Text

hosts:
  http:
    - http://www.google.com:80

--- expected
ok $context->results->[0]->strap->seen == 2;
ok $context->results->[0]->strap->details->[0]{ok} == 1;
ok $context->results->[0]->strap->details->[0]{name} eq 'HTTP status code of http://www.google.com:80 is 200';
ok $context->results->[0]->strap->details->[1]{ok} == 1;
ok $context->results->[0]->strap->details->[1]{name} eq 'Content of http://www.google.com:80 matches \'Google\'';