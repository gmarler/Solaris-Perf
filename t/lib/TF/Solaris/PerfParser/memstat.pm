# NOTE: TF stands for TestsFor::...
package TF::Solaris::PerfParser::memstat;

use Path::Class::File qw();
use Time::Moment      qw();
use File::Temp        qw();
use Data::Dumper      qw();

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
  #}, 'memstat';
}

sub test_parse {
  my $test = shift;

  # TODO:
  # We're using UTC here explicitly, but hosts sending in data will not make
  # that conversion for us, unless we enforce that

  # Expected format:
  #   Epoch secs
  my $tm = Time::Moment->now_utc;
  # Put the first time stamp on the list for checking later
  my @time_bounds = ( $tm );
  diag $tm->strftime("%s");

  my $interval_data = <<EOF;
Page Summary                 Pages             Bytes  %Tot
----------------- ----------------  ----------------  ----
Kernel                     5385475             41.0G   16%
Guest                            0                 0    0%
ZFS Metadata               4241641             32.3G   13%
ZFS File Data              5138150             39.2G   15%
Anon                        550580              4.2G    2%
Exec and libs                12229             95.5M    0%
Page cache                   11767             91.9M    0%
Free (cachelist)             77297            603.8M    0%
Free (freelist)           18071757            137.8G   54%
Total                     33488896            255.5G
EOF

  # TODO:
  # - First and last timestamp check, various data checks of returned info from the
  #   parser
  # - valid keys
  # - valid data (bytes are purely integers)

  my $temp_data_file_fh = File::Temp->new();
  diag "Filename: " . $temp_data_file_fh->filename;

  my $iterations = 500;
  for (my $i = 0; $i < $iterations; $i++) {
    $temp_data_file_fh->print( $tm->strftime("%s") . "\n" );
    $temp_data_file_fh->print( $interval_data );
    $tm = $tm->plus_seconds( 1 );
  }
  # push the last time stamp on the list
  push @time_bounds, $tm;
  $temp_data_file_fh->flush();
  $temp_data_file_fh->seek(0,0);

  ok my $p = $test->class_name->new( datastream => $temp_data_file_fh ),
    'We should be able to create a new instance';

  my $valid_data_count;
  my @valid_keys = qw( datetime kernel guest zfs_metadata zfs_file_data anon
                       exec_and_libs page_cache free_cachelist free_freelist
                       total );
  my ($first_tm, $last_datetime);
  my @returned_time_bounds;
  while (my $data = $p->next()) {
    $valid_data_count++;
    unless ($first_tm++) {
      #push @returned_time_bounds, Time::Moment->from_object( $data->{datetime} );
    }
    $last_datetime = $data->{datetime}; 
    # my $dump = Data::Dumper->new( [$data] );
    # diag $dump->Dump;
    
    # - valid keys
    cmp_bag( [ keys %$data ], \@valid_keys,
             'Valid keys returned for memstat' );
  }
  #push @returned_time_bounds, Time::Moment->from_object( $last_datetime );

  cmp_ok( $iterations, '==', $valid_data_count,
          'Read as much data as we wrote into file' );
}

1;

