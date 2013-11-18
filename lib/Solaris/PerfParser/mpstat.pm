package Solaris::PerfParser::mpstat;

use Moose;
use namespace::autoclean;

# The Date/Time regex, this one should be universal across all *stat
# commands
has 'dt_regex' =>
  ( is => 'ro', isa => 'RegexpRef',
    default => sub {
                qr{^
                   (?: (?:Sun|Mon|Tue|Wed|Thu|Fri|Sat) \s+ # Day of week
                       (?:Jan|Feb|Mar|Apr|May|Jun|
                          Jul|Aug|Sep|Oct|Nov|Dec
                       ) \s+
                       \d+ \s+          # day of month
                       \d+:\d+:\d+ \s+  # HH:MM:DD  (24 hour clock)
                       \w+ \s+          # Time zone (useless)
                       \d{4} \s+        # year
                       \n
                   )
                }smx;
               },
  );

has 'strptime_pattern' => ( is => 'ro', isa => 'Str',
                            default => "%A %B %d %T %z %Y" );


with 'Solaris::PerfParser';

__PACKAGE__->meta->make_immutable;

1;
