use strict;
use warnings;

use Test::Most 'no_plan';
use IO::File;
use Path::Class::File ();
use JSON              ();

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

can_ok($p, qw(new scan record_count datastream) );

$p->scan();

# - There should be 112 "stanzas" in this data file, each prefixed by a
#   timestamp
cmp_ok($p->record_count, '==', 112, 'record_count == 112 records');

ok($p->datastream->eof, "should be at EOF");

# TODO: Make sure that the reset method also resets the record_count
#       simultaneously
cmp_ok($p->reset(), "==", 1, 'reset should return success');
cmp_ok($p->record_count, '==', 0, 'record_count == 0 records after reset');

my ($c, $href);

while ( $href = $p->next() ) {
  $c++;
}

cmp_ok($c, '==', 112, 'next() iterator returned 112 separate records');
cmp_ok($p->record_count, '==', 112, 'record_count == 112 records after next');


#foreach my $href (@{$p->interval_data()}) {
#  my $pretty_printed = JSON->new->allow_blessed->pretty->encode( $href );
#  warn $pretty_printed;
#}

