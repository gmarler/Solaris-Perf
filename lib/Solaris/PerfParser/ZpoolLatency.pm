use strict;
use warnings;

package Solaris::PerfParser::ZpoolLatency;

use namespace::autoclean;

use Moose;
use IO::File                   qw();
use DateTime::Format::Strptime qw();
use DateTime::Set              qw();
use DateTime::Span             qw();
use Fcntl                      qw(SEEK_SET);
use Data::Dumper;

has 'datastream' => ( is       => 'rw',
                      isa      => 'IO::File',
                      required => 1,
                    );

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


# Number of records discovered in the scan
has 'record_count' => ( is => 'rw', isa => 'Int', default => 0 );

has 'read_chunk'   => ( is => 'ro', isa => 'Int', default => 65536 );

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

  my ($fh) = $self->datastream;
  $fh->seek(0, SEEK_SET);
}

sub _parse_record {
}
1;
