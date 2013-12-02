use strict;
use warnings;

package Solaris::PerfParser::mpstat;

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
                \w+ \s+          # Time zone (useless)
                \d{4}            # year
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

  my (%mpstat_data);

  my $mpstat_regex =
    qr{^ (?: \s+? ($<cpu>CPU) [^\n]+ \n |   # mpstat data headers
             \s+? ($<cpu>\d+) \s+ ($<minf>\d+) \s+ ($<mjf>\d+) \s+
             ($<xcal>\d+) \s+ ($<intr>\d+) \s+ ($<ithr>\d+) \s+
             ($<csw>\d+) \s+ ($<icsw>\d+) \s+ ($<migr>\d+) \s+
             ($<smtx>\d+) \s+ ($<srw>\d+) \s+ ($<syscl>\d+) \s+
             ($<usr>\d+) \s+ ($<sys>\d+) \s+ ($<wt>\d+) \s+ ($<idl>\d+) [^\n]+? \n
         )
      }smx;

  # We added 'g' here to get them all, one by one
  while ($data =~ m{ $mpstat_regex }gsmx ) {
    # Skip headers
    next if ($+{cpu} eq "CPU");

    push @{$mpstat_data{'cpu_data'}},
         [ $+{'cpu','minf','mjf','xcal','intr','ithr','csw','icsw','migr',
              'smtx','srw','syscl','usr','sys','wt','idl'} ];
  }
  return \%mpstat_data;
}


__PACKAGE__->meta->make_immutable;

1;
