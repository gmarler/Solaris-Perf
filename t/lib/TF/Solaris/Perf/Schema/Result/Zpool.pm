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

sub test_dbic_insertion {
  my ($test, $report) = @_;

  fixtures_ok [ 
    Zpool => [
      [qw/zpool_name/],
      ["rpool"],
      ["kaos_fs"],
      ["control_fs"],
      ["nydevsol10_fs"],
      ["nydevsol11_fs"],
   ],
  ], 'Installed some custom fixtures via the Populate fixture class';

  # ensure DB now has 5 records
  is Zpool->count, 5, 'now 5 records in host table';

  is_resultset Zpool;
}

1;
