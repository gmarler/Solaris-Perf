# NOTE: TF stands for TestsFor::...
package TF::Solaris::PerfParser::vmstat;

use Test::Class::Moose;
with 'Test::Class::Moose::Role::AutoUse';

use Data::Dumper;

# Set up for schema
#BEGIN { use Solaris::Perf::Schema; }

# Concerning this test file:
# 1. Taken on P315
# 2. Host is in GMT time zone
# 3. Time sample taken: in the 21:00:00 time range
# 4. There are 4 consecutive data samples
#
my $test_datafile = q{vmstat-1sInt-4sec};

sub test_startup {
  my ($test, $report) = @_;
  $test->next::method;

  # ... Anything you need to do to get access to the DB ...
  #use Test::DBIx::Class {
  #  schema_class => 'Solaris::Perf::Schema',
  #}, 'mpstat';
}

sub constructor_args {
  my $filepath =
    Path::Class::File->new(__FILE__)->parent->parent->parent->parent->parent
                     ->file("data",$test_datafile)
                     ->absolute->stringify;

  #  Test datafile should exist
  ok( -f $filepath, "$filepath should exist");

  my $ds = IO::File->new($filepath,"<");

  return( datastream => $ds );
}

sub test_constructor {
  my $test = shift;

  ok my $p = $test->class_name->new($test->constructor_args),
    'We should be able to create a new instance';

  my ($class) = $test->class_name;
  isa_ok($p, $class, "Should be a $class");

  can_ok($p, qw(new scan record_count datastream) );
}

sub test_next {
  my $test = shift;

  ok my $p = $test->class_name->new($test->constructor_args),
    'Create a new instance';

  my ($data,$sample_count);
  my ($start_dt) = DateTime->new( hour => 21, minute => 2, second => 53,
                                  year => 2014, month => 12, day => 16 );

  while ($data = $p->next()) {
    $sample_count++;
    # First sample
    if ($sample_count == 1) {
      cmp_ok($data->{datetime}, '==', $start_dt, 'Start timestamp is correct');
      cmp_ok($data->{vm_data}->{free_list}, '==', 224813328, 'Start free list is correct');
      cmp_ok($data->{vm_data}->{scan_rate}, '==', 0, 'Start scan rate is correct');
      cmp_ok($data->{vm_data}->{idle}, '==', 93, 'Start idle is correct');
    }
  }

  cmp_ok($sample_count, '==', 4, 'Parsed 4 data samples');
}

