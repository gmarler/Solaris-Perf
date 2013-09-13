use strict;
use warnings;

use Test::Most 'no_plan';
use IO::File;
use Path::Class::File ();

my $class = 'Solaris::PerfParser::ZpoolLatency';

use_ok($class);

my $filepath =
  Path::Class::File->new(__FILE__)->parent
                   ->file("data","zpool_heatmap_lat_llquant-20step.out-20130912-1113")
                   ->absolute->stringify;

#  Test datafile should exist
ok( -f $filepath, "$filepath should exist");

my $ds = IO::File->new($filepath,"<");

my $p = Solaris::PerfParser::ZpoolLatency->new(datastream => $ds);

isa_ok($p, $class, "Should be a $class");

$p->scan();

cmp_ok($p->record_count, '==', 112, 'record_count == 112 records');

# TODO:
# - There should be 112 "stanzas" in this data file, each prefixed by a
#   timestamp
#
