package Solaris::PerfParser::memstat;

# VERSION

use Moose;
use namespace::autoclean;

with 'Solaris::PerfParser';

sub _build_dt_regex {
  # This data is extracted from mdb's time::print dcmd, which emits:
  #   YYYY Mon Day HH:MM:SS
  return qr{^
            (?: \d{4} \s+        # year
                (?:Jan|Feb|Mar|Apr|May|Jun|
                   Jul|Aug|Sep|Oct|Nov|Dec
                ) \s+
                \d+ \s+          # day of month
                \d+:\d+:\d+ \s+  # HH:MM:DD  (24 hour clock)
                \n
            )
           }smx;
}

sub _build_strptime_pattern {
  return "%Y %B %d %H:%M:%S",
}


=head2 _parse_interval

Parse data for a single time interval

=cut

sub _parse_interval {
  my ($self,$data) = @_;

  my (%memstat_data);

  my $memstat_regex =
    qr{^ (?: \s+? (?<pgtype>(?:Page|---)) [^\n]+ \n |   # memstat data headers
             \s+? (?<pgtype>(?:Kernel|Defdump\sprealloc|Guest|ZFS\sMetadata|
                               ZFS\sFile\sData|Anon|Exec\sand\slibs|Page\scache|
                               Free\s\(cachelist\)|Free\s\(freelist\)|
                               Total)) \s+
                  (?<pgcount>\d+) \s+
                  (?<bytes>\d+) \s+
                  (?<pct_of_total>\d+)
             \n
         )
      }smx;

  while ($data =~ m{ $memstat_regex }gsmx ) {
    # Skip headers
    next if ($+{pgtype} =~ m{^(?:Page|---)$} );

    my $page_type = $+{pgtype};
    $memstat_data{$page_type} = { };

    my ($page_count,$bytes,$pct_of_total) = $+{'pgcount','bytes','pct_of_total'};

    if ($bytes =~ m/(?<size>\d+)(?<unit>k|M|G|)$/) {
      $bytes = $+{size};
      if ($+{unit} eq '') { # must be in bytes, nothing to do
      } elsif ($+{unit} eq 'k') {
        $bytes *= 1024;
      } elsif ($+{unit} eq 'M') {
        $bytes *= 1024 * 1024;
      } elsif ($+{unit} eq 'G') {
        $bytes *= 1024 * 1024 * 1024;
      }
    }

    $memstat_data{$page_type}->{'page_count','bytes','pct_of_total'} =
      ($page_count, $bytes, $pct_of_total);
  }

  return \%memstat_data;
}



__PACKAGE__->meta->make_immutable;

1;

