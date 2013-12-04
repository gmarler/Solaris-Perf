# NOTE: TF stands for TestsFor::...
package TF::Solaris::PerfParser::pgstat;

use Path::Class::File ();

use Test::Class::Moose;
with 'Test::Class::Moose::Role::AutoUse';

# Set up for schema
BEGIN { use Solaris::Perf::Schema; }

sub test_startup {
  my ($test, $report) = @_;
  $test->next::method;

  # ... Anything you need to do to get access to the DB ...
  #use Test::DBIx::Class {
  #  schema_class => 'Solaris::Perf::Schema',
  #}, 'pgstat';
}

sub constructor_args {
  my $filepath =
    Path::Class::File->new(__FILE__)->parent->parent->parent->parent->parent
                     ->file("data","pgstat-core-1sInt-33sDur-T4-4.out")
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

#
# This is a test of the regex for all *stat commands, particularly the
# date/time stamp followed by a blob of "data"
#
sub test_dt_regex {
  my ($test, $report) = @_;

  my $filepath =
    Path::Class::File->new(__FILE__)->parent->parent->parent->parent->parent
                     ->file("data","pgstat-core-1sInt-33sDur-T4-4.out")
                     ->absolute->stringify;

  #  Test datafile should exist
  ok( -f $filepath, "$filepath should exist");

  my $ds = IO::File->new($filepath,"<");

  # Read the whole file into memory
  my $c = do { local $/; <$ds>; };
  $ds->close;

  my $dt_regex =
           qr{^
            (?: (?:Sun|Mon|Tue|Wed|Thu|Fri|Sat) \s+ # Day of week
                (?:Jan|Feb|Mar|Apr|May|Jun|
                   Jul|Aug|Sep|Oct|Nov|Dec
                ) \s+
                \d+ \s+          # day of month
                \d+:\d+:\d+ \s+  # HH:MM:DD  (24 hour clock)
                \d{4} \s+        # year
                \w+              # Time zone (useless)
                \n
            )
           }smx;

  my $regex =
    qr{(
         $dt_regex   # date-timestamp
         (?:.+?)     # all data after date-timestamp
       )
       # Up to, but not including, the next date/timestamp
       # (?= (?: $dt_regex | \z ) )
       (?= (?: $dt_regex ) )
      }smx;

  my $regex_eof =
    qr{(
         $dt_regex   # date-timestamp
         (?:.+?)     # all data after date-timestamp
       )
       # Up to, but not including, the next date/timestamp
       (?= (?: $dt_regex | \z ) )
      }smx;

  my @subs;
  @subs = $c =~ m{ $regex_eof }gsmx;

  cmp_ok(scalar @subs, '==', 33, 'pgstat matches == 33');
}

sub test_scan {
  my ($test, $report) = @_;

  ok my $p = $test->class_name->new($test->constructor_args),
    'Create a new instance';

  $p->scan();

  # - There should be 33 "stanzas" in this data file, each prefixed by a
  #   timestamp
  cmp_ok($p->record_count, '==', 33, 'record_count == 33 records');

  ok($p->datastream->eof, "should be at EOF");
}

sub test_next {
  my ($test, $report) = @_;

  ok my $p = $test->class_name->new($test->constructor_args),
    'Create a new instance';

  my $data = $p->next();
  my $data2 = $p->next();
}
