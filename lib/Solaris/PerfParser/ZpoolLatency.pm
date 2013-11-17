use strict;
use warnings;
# Enable 'static' variables
use feature    qw( state );

package Solaris::PerfParser::ZpoolLatency;

use namespace::autoclean;

use Moose;
use namespace::autoclean;
use IO::File                   qw();
use DateTime::Format::Strptime qw();
use DateTime::Set              qw();
use DateTime::Span             qw();
use Fcntl                      qw(SEEK_SET);
use JSON                       qw();
use Data::Dumper;

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

has 'read_chunk'   => ( is => 'ro', isa => 'Int', default => 65536 );

my $dt_regex = qr{^
                   (?: \d{4} \s+     # year
                       (?:Jan|Feb|Mar|Apr|May|Jun|
                          Jul|Aug|Sep|Oct|Nov|Dec
                       ) \s+
                       \d+ \s+       # day of month
                       \d+:\d+:\d+   # HH:MM:DD  (24 hour clock)
                       \n
                   )
                 }smx;

my $zpool_action_regex =
    qr{^(\w+) \s+ (\w+) [^\n]+ \n    # zpool and action (write, read, etc)
       ^ \s+ value \s+ [-]+ \s+ Distribution \s+ [-]+ \s+ count [^\n]+ \n # throw away
       # Bucket data comes here...
       (.+?)
       ^$
      }smx;

my ($lat_bucket_regex) =
    qr{^ \s+ (\d+) \s+ \| [@\s]+ (\d+) [^\n]+? \n}smx;


# Regex used to pull individual records from the input, breaking them up into
# a datetime stamp, and the raw data (as $1 and $2)
has 'regex'    => ( is => 'rw', isa => 'RegexpRef',
                    default => sub {
                               qr{(
                                    $dt_regex   # date-timestamp
                                    (?:.+?)     # all data after date-timestamp
                                  )
                                  # Up to, but not including, the next date/timestamp
                                  # (?= (?: $dt_regex | \z ) )
                                  (?= (?: $dt_regex ) )
                                 }smx;
                               },
                  );

# regex to use at EOF
has 'regex_eof' => ( is => 'rw', isa => 'RegexpRef',
                    default => sub {
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
  my ($regex) = $self->regex;
  my ($regex_eof) = $self->regex_eof;
  my ($READ_SZ) = $self->read_chunk;

  my $strp = DateTime::Format::Strptime->new(
    pattern   => '%Y %B %d %T',
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
print them in the desired format, JSON by default

=cut

sub next {
  my ($self) = shift;

  my ($buf);
  # Use a static/stateful variable, as between calls it's likely that you'll
  # have partially consumed/parsed data that you've read from the datastream
  state $c = '';
  my ($regex) = $self->regex;
  my ($regex_eof) = $self->regex_eof;
  my ($READ_SZ) = $self->read_chunk;

  my $strp = DateTime::Format::Strptime->new(
    pattern   => '%Y %B %d %T',
    #pattern   => '%A,%t%B%t%d,%t%Y%t%I:%M:%S%t%p',
    time_zone => 'floating',
    on_error  => 'croak',
  );

  if (scalar(@{$self->interval_data})) {
    return shift @{$self->interval_data};
  }

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
        my ($dt) = $strp->parse_datetime($dt_stamp);
        # TODO: Parse the individual data sections into something we can print
        # out directly in any format
        my ($data) = $self->_parse_interval($coredata);
        $data->{datetime} = $dt;
        push @{$self->interval_data}, $data;
      }
      # Delete what we've parsed so far...
      if ($self->datastream->eof) {
        $drops = $c =~ s{ $regex_eof }{}gsmx;
      } else {
        $drops = $c =~ s{ $regex }{}gsmx;
      }
      $self->record_count($self->record_count + $drops);
    }
  } until (scalar(@{$self->interval_data}) or $self->datastream->eof);

  if ( scalar(@{$self->interval_data}) ) {
    return shift @{$self->interval_data};
  } else {
    return;  # undef
  }

  ##### INITIAL BAD IDEA
#  my (@data) = @{$self->data};
#
#  foreach my $entry (@data) {
#    my ($datetime) = $entry->{datetime}->strftime("%x %X");
#    foreach my $bucket (sort { $a <=> $b } keys %{$entry->{'action'}->{'ALL'}})
#    {
#      my $count = $entry->{'action'}->{'ALL'}->{$bucket};
#      print "{ \"datetime\": \"$datetime\", \"bucket\": $bucket, \"count\": $count }\n";
#    }
#  }
  #####
}

=head2 _parse_interval

Parse data for a single time interval

=cut

sub _parse_interval {
  my ($self,$data) = @_;

  my (%bucket_data);

  # We added 'g' here to get them all, one by one
  while ($data =~ m{ $zpool_action_regex }gsmx ) {
    my ($zpool,$action,$buckets) = ($1,$2,$3);

    # For each "action" in this zpool, tear the buckets apart and
    # build the data structure
    my (%processed) = %{$self->_parse_record($zpool,$action,$buckets)};
    @bucket_data{keys %processed} = values %processed;
  }
  return \%bucket_data;
}

=head2 _parse_record

Parse data for a single record inside a time interval

=cut

sub _parse_record {
  my ($self,$zpool,$action,$buckets) = @_;
  my (%bucket_data);

  while ($buckets =~ m{ $lat_bucket_regex }gsmx) {
    my ($bucket,$count) = ($1,$2);
    $bucket_data{'zpool'} = $zpool;
    $bucket_data{'action'}->{$action}->{$bucket} = $count;
    # aggregate read/write activity latency
    if ($action =~ m/read/) {
      $bucket_data{'action'}->{'read'}->{$bucket} += $count;
    } elsif ($action =~ m/write/) {
      $bucket_data{'action'}->{'write'}->{$bucket} += $count;
    } else {
      die "Unable to determine aggregate action type!";
    }
    # And, aggregate *everything*
    $bucket_data{'action'}->{'ALL'}->{$bucket} += $count;
  }
  return \%bucket_data;
}


__PACKAGE__->meta->make_immutable;

1;
