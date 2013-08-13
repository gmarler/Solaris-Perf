use strict;
use warnings;
use Test::Most;

BEGIN { use_ok 'Solaris::Perf'; }

use Test::DBIx::Class {
  schema_class => 'Solaris::Perf::Schema',
}, 'FS';


# ensure DB is empty
is FS->count, 0, 'no records in host table';

fixtures_ok [ 
    FS => [
        [qw/mountpoint/],
        ["/bb/data"],
        ["/bb/pm"],
        ["/bb/bigmem"],
    ],
], 'Installed some custom fixtures via the Populate fixture class';

# ensure DB now has 3 records
is FS->count, 3, 'now 3 records in filesystem table';

is_resultset FS;

# Look for a known filesystem
ok my $fs = FS->find({mountpoint => '/bb/data'}) =>
  'found primary filesystem';

# Ensure we can't find a non-existent filesystem
my $nonfs = FS->find({ mountpoint => '/insane/path'});

is($nonfs,undef,"Cannot find non-existent filesystem");

# Make sure we know all of the filesystems are in the DB
my @got = map { $_->mountpoint } FS->all();

cmp_bag(\@got,[ "/bb/bigmem", "/bb/pm", "/bb/data" ],"all filesystems returned");

my $ffs = FS->first()->mountpoint();
cmp_deeply([$ffs],subsetof( qw(/bb/pm /bb/bigmem /bb/data) ),
    "First filesystem should be in list of all filesystems");

done_testing;
