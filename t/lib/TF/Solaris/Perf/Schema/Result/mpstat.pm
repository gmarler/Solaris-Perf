# NOTE: TF stands for TestsFor::...
package TF::Solaris::Perf::Schema::Result::mpstat;

use Data::Dumper;
use Path::Class::File ();

use Test::Class::Moose;
with 'Test::Class::Moose::Role::AutoUse';

# Set up for schema
BEGIN { use Solaris::Perf::Schema;
        use Solaris::PerfParser::mpstat;
      }

sub test_startup {
  my ($test, $report) = @_;
  $test->next::method;

  use Test::DBIx::Class {
    schema_class => 'Solaris::Perf::Schema',
  }, 'Host', 'Interval', 'HostInterval', 'mpstat';
}

sub mpstat_parser_constructor_args {
  my $filepath =
    Path::Class::File->new(__FILE__)->parent->parent->parent->parent->parent
                     ->parent->parent
                     ->file("data","mpstat-1sInt-15sDur-x64.out")
                     ->absolute->stringify;

  #  Test datafile should exist
  ok( -f $filepath, "$filepath should exist");

  my $ds = IO::File->new($filepath,"<");

  return( datastream => $ds );
}

sub test_mpstat_parser_constructor {
  my ($test, $report) = @_;

  my $class_name = "Solaris::PerfParser::mpstat";

  ok my $p = $class_name->new($test->mpstat_parser_constructor_args),
    'We should be able to create a new instance';

  my ($class) = $class_name;
  isa_ok($p, $class, "Should be a $class");

  can_ok($p, qw(new scan record_count datastream) );
}

sub test_dbic_insertion {
  my ($test, $report) = @_;

  fixtures_ok [ 
    Host => [
      [qw/name/],
      ["fwsse37"],
      ["kaos"],
      ["control"],
      ["nydevsol10"],
      ["nydevsol11"],
   ],
  ], 'Installed some custom fixtures via the Populate fixture class';

  # ensure DB now has 5 records
  is Host->count, 5, 'now 5 records in host table';

  is_resultset Host;
}


sub test_populate_from_parse {
  my ($test, $report) = @_;

  my $parser_class_name = "Solaris::PerfParser::mpstat";

  ok my $p = $parser_class_name->new($test->mpstat_parser_constructor_args),
    'We should be able to create a new parser instance';

  my ($class) = $parser_class_name;
  isa_ok($p, $class, "Should be a $class");

  ok my $host_id = Host->find_or_create({name => 'proteus'}) =>
    'Should find previously existing host proteus';

  my $dtf = Schema->storage->datetime_parser;

  # Read and parse datastream
  while (my $interval_data = $p->next()) {
    # Grab the interval timestamp and insert it
    my $dt = $interval_data->{datetime};
    my $interval_result = Interval->find_or_create({ start => $dtf->format_datetime($dt) });
    isa_ok($interval_result, "Solaris::Perf::Schema::Result::Interval",
          'Should be a Result::Interval');
    # Validate the timestamp
    # Insert the rows for this interval in the mpstat table
    # NOTE: $cd is short for $cpu_data
    my $cd = $interval_data->{cpu_data};
    foreach my $crow (@$cd) {
      my $row = mpstat->create({
          host_id => $host_id, interval_id => $interval_result->id,
          cpu => $crow->[0], xcal => $crow->[3], usr => $crow->[12],
          sys => $crow->[13], idl => $crow->[15],
        }
      );
      isa_ok($row, "Solaris::Perf::Schema::Result::mpstat",
             'Should be a Result::mpstat');
    }
    # Validate them
  }

  # Validate the count and range of timestamps that were inserted
}

1
