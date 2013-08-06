use strict;
use warnings;
use Test::Most;

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

# ensure DB now has 2 records
is Host->count, 2, 'now 2 records in host table';

is_resultset Host;

# Look for a known host
ok my $host = Host->find({name => 'fwsse37'}) =>
  'found my Fort Worth host';

# Ensure we can't find a non-existent host
my $nonhost = Host->find({ name => 'control'});

is($nonhost,undef,"Cannot find Max's computer, as expected");

# Make sure we know all of the hosts are in the DB
my @got = map { $_->name } Host->all();

cmp_bag(\@got,[ "kaos", "fwsse37" ],"all hosts returned");

my $fhost = Host->first()->name();
cmp_deeply([$fhost],subsetof( qw(kaos fwsse37) ),
    "First host should be in list of all hosts");

done_testing;
