use strict;
use warnings;
use Test::More;

BEGIN {
  use_ok('Catalyst::Test', 'Solaris::Perf');
  use_ok('DBICx::TestDatabase');
}

done_testing();
