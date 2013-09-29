# NOTE: TF stands for TestsFor::...
package TF::Solaris::PerfParser::ZpoolLatency;

use Path::Class::File ();

use Test::Class::Moose;
with 'Test::Class::Moose::Role::AutoUse';

# Set up for schema
BEGIN { use Solaris::Perf; }

sub test_startup {
  my ($test, $report) = @_
  $test->next::method;

  use Test::DBIx::Class {
    schema_class => 'Solaris::Perf::Schema',
  }, 'Host', 'Zpool', 'IOAction', 'Interval', 'ZPoolLat';

  fixtures_ok [ 
    Host => [
      [qw/name/],
      ["fwsse37"],
      ["kaos"],
    ],
  ], 'Installed some custom fixtures via the Populate fixture class';
}



sub constructor_args {
  my $filepath =
    Path::Class::File->new(__FILE__)->parent->parent->parent->parent->parent
                     ->file("data","zpool_heatmap_lat_llquant-20step.out-20130912-1113")
                     ->absolute->stringify;

  #  Test datafile should exist
  ok( -f $filepath, "$filepath should exist");

  my $ds = IO::File->new($filepath,"<");

  return( datastream => $ds );
}

sub test_constructor {
  my ($test, $report) = @_;

  ok my $p = $test->class_name->new($test->constructor_args),
    'We should be able to create a new instance';

  my ($class) = $test->class_name;
  isa_ok($p, $class, "Should be a $class");

  can_ok($p, qw(new scan record_count datastream) );
}

sub test_scan {
  my ($test, $report) = @_;

  ok my $p = $test->class_name->new($test->constructor_args),
    'Create a new instance';

  $p->scan();

  # - There should be 112 "stanzas" in this data file, each prefixed by a
  #   timestamp
  cmp_ok($p->record_count, '==', 112, 'record_count == 112 records');

  ok($p->datastream->eof, "should be at EOF");
}

sub test_dbic_insertion {
  my ($test, $report) = @_;

# ensure DB now has 2 records
  is Host->count, 2, 'now 2 records in host table';

  is_resultset Host;

}

1;
