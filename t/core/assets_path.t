use strict;
use t::TestAssurer;

plan 'no_plan';
run_eval_expected_with_capture;

__END__

=== Test global:assets_path
--- input config
global:
  log:
    level: debug

test:
  - module: AssetsPath
    name: Dumb Test
    role: dumb

hosts:
  dumb:
    - dumb
      
--- expected
like $warnings, qr/OK/;
like $warnings, qr/OK/;
like $warnings, qr/OK/;
like $warnings, qr/OK/;