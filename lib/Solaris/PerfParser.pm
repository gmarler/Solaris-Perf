use strict;
use warnings;

package Solaris::PerfParser;

# Enable 'static' variables
use feature    qw( state );

use Moose::Role;
use namespace::autoclean;
use IO::File                     qw();
use DateTime::Format::Strptime   qw();
use DateTime::Set                qw();
use DateTime::Span               qw();
use Fcntl                        qw(SEEK_SET);
use Moose::Util::TypeConstraints;
use Solaris::DTF::Stats          qw();

requires '_build_dt_regex';
requires '_build_strptime_pattern';
requires '_parse_interval';

# Define these, so we can use them in type unions below as needed
class_type 'IO::Handle';
class_type 'IO::File';
class_type 'IO::All::File';
class_type 'IO::Uncompress::Bunzip2';

has 'datastream' => ( is       => 'rw',
                      isa      => 'IO::Handle | IO::File | IO::All::File | IO::Uncompress::Bunzip2',
                      required => 1,
                    );

# TODO: POD document
# If start/end are defined upon object construction, then we will seek
# the datastream until we find them
has 'start'          => ( is      => 'rw',
                          isa     => 'Maybe[DateTime]',
                          default => undef,
                        );

has 'end'            => ( is      => 'rw',
                          isa     => 'Maybe[DateTime]',
                          default => undef,
                        );

# Whether the two DateTimes above have been 'primed'; that is, whether
# they have had the year/month/day copied from the file we're parsing
# into these DateTimes.
has 'dt_primed'      => ( is      => 'rw',
                          isa     => 'Bool',
                          default => 0,
                        );

# TODO: POD document!
# If we need to collapse/coalesce the data, not necessarily keeping the
# timestamps once we've extracted the data from the proper time frame, then
# we'll need to set this to True.
# This is handy for DTrace stack traces when creating Flame Graphs from them
# after collapsing/coalescing them.
has 'strip_datetime' => ( is      => 'ro',
                          isa     => 'Bool',
                          default => 0,
                        );

# TODO: POD document
# This is something we'll set false if we don't want to further parse the
# data, such as DTrace stack traces, which need no further parsing other
# than collecting them from the right time range, then removing the
# timestamps for subsequent collapsing.
has 'interval_subparse' => ( is      => 'ro',
                             isa     => 'Bool',
                             default => 1,
                           );


has 'interval_data' => ( is      => 'rw',
                         isa     => 'ArrayRef[HashRef]',
                         default => sub { [] },
                       );

# Number of records discovered in the scan
has 'record_count' => ( is => 'rw', isa => 'Int', default => 0 );

# The size of each chunk read from the datastream
has 'read_chunk'   => ( is => 'ro', isa => 'Int', default => 65536 );

# The Date/Time regex, should be universal across all *stat and other
# data gathering applications
has 'dt_regex' => (
  is      => 'ro',
  isa     => 'RegexpRef',
  lazy    => 1,
  builder => '_build_dt_regex',
);

has 'datetime_parser' => (
  is      => 'ro',
  isa     => 'Object',
  lazy    => 1,
  builder => '_build_datetime_parser',
);

has 'strptime_pattern' => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_strptime_pattern',
);

# Regex used to pull individual records from the input, breaking them up into
# a datetime stamp, and the raw data (as $1 and $2)
has 'regex'    => ( is => 'rw', isa => 'RegexpRef',
                    lazy => 1, # Must be lazy because it depends on dt_regex
                    default => sub {
                                 my $self = shift;
                                 my $dt_regex = $self->dt_regex;
                               qr{(
                                    $dt_regex   # date-timestamp
                                    (?:.+?)     # all data after date-timestamp
                                  )
                                  # Up to, but not including, the next date/timestamp
                                  # (?= (?: $self->dt_regex | \z ) )
                                  (?= (?: $dt_regex ) )
                                 }smx;
                               },
                  );

# regex to use at EOF
has 'regex_eof' => ( is => 'rw', isa => 'RegexpRef',
                     lazy => 1, # Must be lazy because it depends on dt_regex
                     default => sub {
                                  my $self = shift;
                                  my $dt_regex = $self->dt_regex;
                                qr{(
                                     $dt_regex   # date-timestamp
                                     (?:.+?)     # all data after date-timestamp
                                   )
                                   # Up to, but not including, the next date/timestamp
                                   (?= (?: $dt_regex | \z ) )
                                  }smx;
                                },
                   );

sub scan {
  my ($self) = shift;

  my ($buf, $c);
  my ($dt_regex)  = $self->dt_regex;
  my ($regex)     = $self->regex;
  my ($regex_eof) = $self->regex_eof;
  my ($READ_SZ)   = $self->read_chunk;

  my $datetime_parser = $self->datetime_parser;

  my $i = 0;
  while ($self->datastream->read($buf,$READ_SZ)) {
    $c .= $buf;
    # Extract as many whole sections as possible, process, then
    # continue on
    my (@subs);
    # If we're at the end of the file, then we need to use a special case regex
    if ($self->datastream->eof) {
      @subs = $c =~ m{ $regex_eof }gsmx;
    } else {
      @subs = $c =~ m{ $regex }gsmx;
    }
    if (@subs) {
      my ($data,$dt_stamp,$coredata,$drops);
      for (my $i = 0; $i < scalar(@subs); $i++) {
        $data = $subs[$i];
        # Break out timestamp, parse into DateTime object
        ($dt_stamp) = $data =~ m/ ($dt_regex) /smx;
        chomp $dt_stamp;
        ($coredata = $data) =~ s/ $dt_regex //smx;
        # Rip out the time zone so parse_datetime will accept the $dtstamp
        $dt_stamp =~ s{\w+ \s+ (\d{4})$}{$1}x;
        # Of course, some like pgstat are different (the time zone comes last)
        $dt_stamp =~ s{(\d{4}) \s+ \w+$}{$1}x;
        my ($dt) = Solaris::DTF::Stats->parse_datetime($dt_stamp);
        # TODO: Find a way to store the $coredata we need to examine eventually
        # push @{$dt_aref} = $dt;
      }
      # Delete what we've parsed so far...
      if ($self->datastream->eof) {
        $drops = $c =~ s{ $regex_eof }{}gsmx;
      } else {
        $drops = $c =~ s{ $regex }{}gsmx;
      }
      $self->record_count($self->record_count + $drops);
    }
  }
}

sub reset {
  my ($self) = shift;

  $self->record_count(0);
  $self->datastream->seek(0, SEEK_SET);
}

=head2 next

Pull all the records for the next time interval off of the datastream and
store them in the object's interval_data attribute.

if start and end DateTime's are defined, then make sure we're in the range
specified before returning anything.

=cut

sub next {
  my ($self) = shift;
  my ($buf);

  # Use a static/stateful variable, as between calls it's likely that you'll
  # have partially consumed/parsed data that you've read from the datastream
  state $c = '';

  my ($dt_regex)  = $self->dt_regex;
  my ($regex)     = $self->regex;
  my ($regex_eof) = $self->regex_eof;
  my ($READ_SZ)   = $self->read_chunk;
  # when we first pull these, they're only times, no year/month/day - we need
  # to populate them from the first datetime we read out of the file
  my ($start_dt)  = $self->start;
  my ($end_dt)    = $self->end;
  # Set to show you've primed the DateTimes from the file we're parsing
  my ($dt_primed) = $self->dt_primed;
  # If a time range has been specified, whether we've exhausted the range of
  # times of interest
  my ($time_range_exhausted);

  # If we have already parsed data, return it one interval at a
  # time
  # CONSTRAINT: When start_dt/end_dt defined, any data already parsed and ready
  #             for reading should be within the specified range
  if (scalar(@{$self->interval_data}) and (not $time_range_exhausted)) {
    return shift @{$self->interval_data};
  }

  # If the interval data is exhausted, try to extract more from the datastream
  do {
    $self->datastream->read($buf,$READ_SZ);
    $c .= $buf;
    # Extract as many whole sections as possible, process, then
    # continue on
    my (@subs);
    # If we're at the end of the file, then we need to use a special case regex
    if ($self->datastream->eof) {
      @subs = $c =~ m{ $regex_eof }gsmx;
    } else {
      @subs = $c =~ m{ $regex }gsmx;
    }
    if (@subs) {
      my ($data,$dt_stamp,$coredata,$esecs,$drops);
      for (my $i = 0; $i < scalar(@subs); $i++) {
        $data = $subs[$i];
        # Break out timestamp, parse into DateTime object
        ($dt_stamp) = $data =~ m/ ($dt_regex) /smx;
        chomp $dt_stamp;
        ($coredata = $data) =~ s/ $dt_regex //smx;
        # Rip out the time zone so parse_datetime will accept the $dtstamp
        $dt_stamp =~ s{\w+ \s+ (\d{4})$}{$1}x;
        # Of course, some like pgstat are different (the time zone comes last)
        $dt_stamp =~ s{(\d{4}) \s+ \w+$}{$1}x;
        my ($dt) = Solaris::DTF::Stats->parse_datetime($dt_stamp);

        # Only do this if the begin/end timestamps have been defined
        if (defined($start_dt) and defined($end_dt)) {
          unless ($dt_primed) {
            my ($year,$month,$day) = ($dt->year, $dt->month, $dt->day);

            $start_dt = DateTime->new( year => $year, month => $month, day => $day );
            $end_dt   = DateTime->new( year => $year, month => $month, day => $day );

            $self->start($start_dt);   $self->end($end_dt);
            $dt_primed = $self->dt_primed(1);
          }
        }

        # Exit the loop here if we've passed the end of the interesting time range
        if (defined($end_dt) and ($dt > $end_dt)) {
          $time_range_exhausted++;
          last;
        }
        # TODO: Parse the individual data sections into something we can print
        #       out directly in any format
        my $data;
        if ($self->interval_subparse) {
          $data = $self->_parse_interval($coredata);
          $data->{datetime} = $dt;
        } else {
          $data = $coredata;
        }
        # Handle whether we're looking for a specific range or not
        if ($start_dt and $end_dt) {
          if (($start_dt <= $dt) and ($dt <= $end_dt)) {
            push @{$self->interval_data}, $data;
          }
        } else {
          push @{$self->interval_data}, $data;
        }
      }
      # Delete what we've parsed so far from our contents buffer...
      if ($self->datastream->eof) {
        $drops = $c =~ s{ $regex_eof }{}gsmx;
      } else {
        $drops = $c =~ s{ $regex }{}gsmx;
      }
      # Update the record count
      $self->record_count($self->record_count + $drops);
    }
  } until (scalar(@{$self->interval_data}) or $self->datastream->eof or
           $time_range_exhausted);

  if ( (not $time_range_exhausted) and scalar(@{$self->interval_data}) ) {
    return shift @{$self->interval_data};
  } else {
    return;  # undef
  }
}

# This doesn't seem to work for Roles
# __PACKAGE__->meta->make_immutable;

1;

