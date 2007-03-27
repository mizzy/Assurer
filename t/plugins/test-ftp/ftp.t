use strict;
use t::TestAssurer;

test_plugin_deps;
test_requires_network;
plan 'no_plan';
run_eval_expected;

__END__

=== Test test
--- input config
global:
  exclude_no_result_test: 1

test:
  - module: FTP
    config:
      user: anonymous
      password: 
    role: ftp

format:
  - module: Text

hosts:
  ftp:
    - ftp2.fr.debian.org

--- expected
ok $context->results->[0]->strap->seen == 2;
ok $context->results->[0]->strap->details->[0]{ok} == 1;
ok $context->results->[0]->strap->details->[0]{name} eq 'connect to ftp2.fr.debian.org';
ok $context->results->[0]->strap->details->[1]{ok} == 1;
ok $context->results->[0]->strap->details->[1]{name} eq 'login to ftp2.fr.debian.org';
