# NOTE: TF stands for TestsFor::...
package TF::Solaris::Perf::Schema::Result::Host;

use Data::Dumper;

use Test::Class::Moose;
with 'Test::Class::Moose::Role::AutoUse';

# Set up for schema
BEGIN { use Solaris::Perf; }

sub test_startup {
  my ($test, $report) = @_;
  $test->next::method;

  use Test::DBIx::Class {
    schema_class => 'Solaris::Perf::Schema',
  }, 'Host';
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

sub test_host_lookup {
  my ($test, $report) = @_;

  # positive existence
  ok my $host = Host->find({name => 'kaos'}) =>
    'Should be able to find kaos';
  is_fields 'name', $host, [ 'kaos' ] =>
    'Found kaos';
  isa_ok $host, 'DBIx::Class::Row' => 'should be a row';
  ok my $exists = Host->find_or_create({name => 'nydevsol10'}) =>
    'Should find existing host nydevsol10';
  is_fields 'name', $exists, [ 'nydevsol10' ] =>
    'Found nydevsol10';
  ok my $new_host = Host->find_or_create({name => 'proteus'}) =>
    'Should create new host proteus';
  is_fields [ qw/name/ ], $new_host, [ 'proteus' ] =>
    'Found proteus';
  # negative existence
  my $ne_host = Host->find({name => 'ether'});
  is $ne_host, undef, 'Non-existent host not found, as expected';
  # TODO: Deletion
  # Weird errors about Zpool here...
  #warn Dumper $host;
  ok $host->delete => 'Deleting kaos successfully';
  my $del_host = Host->find({name => 'kaos'});
  is $del_host, undef, 'kaos is now gone';
  # Rename
  ok $new_host->update({name => 'Denise'}) =>
    'proteus has been renamed to Denise';
  # Insertion
  # Verify all rows
}

1;
