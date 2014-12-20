use feature ':5.18';
use strict;
use warnings;

package Solaris::DTF::Stats;

# VERSION

use DateTime           qw();
use DateTime::TimeZone qw();

use DateTime::Format::Builder (
  # 2014 Nov  5 11:41:47
  # OR
  # Epoch seconds
  parsers => {
    parse_datetime => [
      {
        # Parse epoch secs
        params => [qw( epoch )],
        regex  => qr/^ (\d+) $/x,
        constructor => [ 'DateTime', 'from_epoch' ],
      },
      {
        strptime => '%Y %B %d %H:%M:%S',
      },
      {
        regex => qr/^(\d{4}) \s+ (\w{3}) \s+ (\d+) \s+
                     (\d+):(\d+):(\d+)$/x,
        params => [qw( year month day hour minute second )],
      },
      {
        length => 8,
        regex  => qr/^(\d{2}):(\d{2}):(\d{2})$/x,
        params => [qw( hour minute second )],
        extra  => { time_zone => 'floating' },
        preprocess  => \&_add_in_fake_date,
      }
    ]
  }
);

sub _add_in_fake_date {
  my %args = @_;
  my ($date, $p) = @args{qw( input parsed )};
  # Yeah, the month and day have to be between 1 and 12
  @{$p}{qw( year month day )} = (0, 1, 1);
  return $date;
}

1;

