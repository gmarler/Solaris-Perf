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

=head2 _parse_interval

Parse data for a single time interval

=cut

sub _parse_interval {
  my ($self,$data) = @_;

  my (%pgstat_data);

  my $pgstat_regex =
    qr{^ (?: \s+? (?<id>ID) [^\n]+ \n |   # pgstat data headers
             \s+? (?<id>\d+) \s+
             Core \s+ \( (?<core_resource>\w+) \) \s+
             (?<hw>(?:-|\d|\.)+)%? \s+
             (?<sw>(?:-|\d|\.)+)%? \s+
             (?<cpus>\S+) \n \n?
         )
      }smx;

  # We added 'g' here to get them all, one by one
  while ($data =~ m{ $pgstat_regex }gsmx ) {
    # Skip headers
    next if ($+{id} eq "ID");

    push @{$pgstat_data{'core_data'}},
         [ @+{'id','core_resource','hw','sw','cpus'} ];
  }
  return \%pgstat_data;
}


__PACKAGE__->meta->make_immutable;

1;
