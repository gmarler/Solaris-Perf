use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Solaris::Perf'; }

use Test::DBIx::Class {
  schema_class => 'Solaris::Perf::Schema',
}, 'Host';


# ensure DB is empty
is Host->count, 0, 'no records in host table';

fixtures_ok [ 
    Host => [
        [qw/name/],
        ["fwsse37"],
        ["kaos"],
    ],
], 'Installed some custom fixtures via the Populate fixture class';

# ensure DB is empty
is Host->count, 2, 'now 2 records in host table';

is_resultset Host;

ok my $host = Host->find({name => 'fwsse37'}) =>
  'found my Fort Worth host';

my $nonhost = Host->find({ name => 'control'});

is($nonhost,undef,"Cannot find Max's computer");


done_testing;
