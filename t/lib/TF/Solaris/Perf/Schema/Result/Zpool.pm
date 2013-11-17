# NOTE: TF stands for TestsFor::...
package TF::Solaris::Perf::Schema::Result::Zpool;

use Test::Class::Moose;
with 'Test::Class::Moose::Role::AutoUse';

# Set up for schema
BEGIN { use Solaris::Perf::Schema; }

sub test_startup {
  my ($test, $report) = @_;
  $test->next::method;

  use Test::DBIx::Class {
    schema_class => 'Solaris::Perf::Schema',
  }, 'Host', 'Zpool', 'HostZpool';
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
   Host   => [
      [qw/name/],
      ["alder"],
   ],
  ], 'Installed some custom fixtures via the Populate fixture class';

  # ensure DB now has 5 records
  is ResultSet('Zpool')->count, 5, 'now 5 records in host table';

  is_resultset Zpool;

  ok my $alder = Host->find_or_create({name => 'alder'}) =>
    'Should insert/create new host alder';
  isa_ok $alder, 'DBIx::Class::Row', "returned alder is a Row";
  # Insert related zpools for host alder
  #$alder->create_related(
  #  'zpools', {
  #    zpool_name => 'alder_fs',
  #});
  # Another way to do the same thing (different zpool for same host)
  $alder->add_to_zpools(
    {
      'zpool_name' => 'rpool',
    }
  );
}

1;
