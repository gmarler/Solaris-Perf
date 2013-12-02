use strict;
use warnings;

package Solaris::PerfParser;

# Enable 'static' variables
use feature    qw( state );

use Moose::Role;
use namespace::autoclean;
use IO::File                   qw();
use DateTime::Format::Strptime qw();
use DateTime::Set              qw();
use DateTime::Span             qw();
use Fcntl                      qw(SEEK_SET);

requires '_build_dt_regex';
requires '_build_strptime_pattern';
requires '_parse_interval';

has 'datastream' => ( is       => 'rw',
                      isa      => 'IO::File',
                      required => 1,
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

#                    default => sub {
#                    qr{^
#                        (?: \d{4} \s+     # year
#                          (?:Jan|Feb|Mar|Apr|May|Jun|
#                            Jul|Aug|Sep|Oct|Nov|Dec
#                          ) \s+
#                          \d+ \s+       # day of month
#                          \d+:\d+:\d+   # HH:MM:DD  (24 hour clock)
#                          \n
#                        )
#                      }smx;
#                    },
#                  );

#has 'strptime_pattern' => ( is => 'ro', isa => 'Str',
#                            default => "%A %B %d %T %z %Y" );
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

  my $strp = DateTime::Format::Strptime->new(
    pattern   => $self->strptime_pattern,
    time_zone => 'floating',
    on_error  => 'croak',
  );

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
        my ($dt) = $strp->parse_datetime($dt_stamp);
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
store them in the object's interval_data attribute

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

  my $strp = DateTime::Format::Strptime->new(
    pattern   => $self->strptime_pattern,
    #pattern   => '%A,%t%B%t%d,%t%Y%t%I:%M:%S%t%p',
    time_zone => 'floating',
    on_error  => 'croak',
  );

  # If we have already parsed data, return it one interval at a
  # time
  if (scalar(@{$self->interval_data})) {
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
        my ($dt) = $strp->parse_datetime($dt_stamp);
        # TODO: Parse the individual data sections into something we can print
        #       out directly in any format
        my ($data) = $self->_parse_interval($coredata);
        $data->{datetime} = $dt;
        push @{$self->interval_data}, $data;
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
  } until (scalar(@{$self->interval_data}) or $self->datastream->eof);

  if ( scalar(@{$self->interval_data}) ) {
    return shift @{$self->interval_data};
  } else {
    return;  # undef
  }
}


# This doesn't seem to work for Roles
# __PACKAGE__->meta->make_immutable;

1;
