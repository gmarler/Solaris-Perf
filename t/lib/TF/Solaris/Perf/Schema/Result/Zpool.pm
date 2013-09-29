# NOTE: TF stands for TestsFor::...
package TF::Solaris::Perf::Schema::Result::Zpool;

use Test::Class::Moose;
with 'Test::Class::Moose::Role::AutoUse';

# Set up for schema
BEGIN { use Solaris::Perf; }

sub test_startup {
  my ($test, $report) = @_;
  $test->next::method;

  use Test::DBIx::Class {
    schema_class => 'Solaris::Perf::Schema',
  }, 'Zpool';
}

#sub test_dbic_insertion {
#  my ($test, $report) = @_;
#
#  fixtures_ok [ 
#    Host => [
#      [qw/name/],
#      ["fwsse37"],
#      ["kaos"],
#      ["control"],
#      ["nydevsol10"],
#      ["nydevsol11"],
#   ],
#  ], 'Installed some custom fixtures via the Populate fixture class';
#
#  # ensure DB now has 2 records
#  is Host->count, 2, 'now 2 records in host table';
#
#  is_resultset Host;
#}

1;
