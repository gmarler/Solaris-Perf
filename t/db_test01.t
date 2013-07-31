use strict;
use warnings;
use Test::More;
use Test::DBIx::Class {
  schema_class => 'Solaris::Perf::Schema',
}, 'Host';

# ensure DB is empty
is Host->count, 0, 'no records in host table';


done_testing;
