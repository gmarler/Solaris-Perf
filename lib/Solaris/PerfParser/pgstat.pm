use strict;
use warnings;

package Solaris::PerfParser::pgstat;

use Moose;
use namespace::autoclean;

with 'Solaris::PerfParser';

sub _build_dt_regex {
  return qr{^
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
}

sub _build_strptime_pattern {
  return "%A %B %d %T %Y";
}

__PACKAGE__->meta->make_immutable;

1;
