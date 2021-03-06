package Solaris::PerfParser::memstat;

# VERSION

use Moose;
use namespace::autoclean;

with 'Solaris::PerfParser';

sub _build_dt_regex {
  # this data is extracted from mdb's dcmd of the following form:
  # time::print -d ! sed -e 's/^0t//'
  # which *should be* epoch secs
  return qr{^
            (?: \d+     # Epoch secs
                \n
            )
           }smx;
}

sub _build_strptime_pattern {
  return "%s";
}


=head2 _parse_interval

Parse data for a single time interval

=cut

sub _parse_interval {
  my ($self,$data) = @_;

  my (%memstat_data);

  # TODO: Total doesn't yet work, so fix it, as it doesn't have the
  #       pct_of_total column
  my $memstat_regex =
    qr{^ (?: (?<pgtype>(?:Page\sSummary|---)) [^\n]+ \n |   # memstat data headers
             (?<pgtype>(?:Kernel|Defdump\sprealloc|Guest|ZFS\sMetadata|
                          ZFS\sFile\sData|Anon|Exec\sand\slibs|Page\scache|
                          Free\s\(cachelist\)|Free\s\(freelist\)|
                          In\stemporary\suse))          \s+
             (?<pgcount>\d+)               \s+
             (?<bytes>\d+(?:\.\d+)?(?:[kMG])?)  \s+
             (?<pct_of_total>\d+)\%
             \n
         ) |
         (?: (?<pgtype>Total) \s+
             (?<pgcount>\d+)  \s+
             (?<bytes>\d+(?:\.\d+)?(?:k|M|G|)?) \n )
      }smx;

  while ($data =~ m{ $memstat_regex }gsmx ) {
    # Skip headers
    next if ($+{pgtype} =~ m{^(?:Page\sSummary|In\stemporary\suse|---)$} );

    my ($page_type,$page_count,$bytes,$pct_of_total) =
      @+{ qw(pgtype pgcount bytes pct_of_total) };

    # Fix $page_type names so they can be used as hash keys
    $page_type = lc($page_type);
    $page_type =~ s/[()]//g;
    $page_type =~ s/\s+/_/g;  # Replace spaces with underscores

    $memstat_data{$page_type} = { };

    if ($bytes =~ m/(?<size>\d+(?:\.\d+)?)(?<unit>k|M|G|)$/) {
      $bytes = $+{size};
      if ($+{unit} eq '') { # must be in bytes, nothing to do
      } elsif ($+{unit} eq 'k') {
        $bytes *= 1024;
      } elsif ($+{unit} eq 'M') {
        $bytes *= 1024 * 1024;
      } elsif ($+{unit} eq 'G') {
        $bytes *= 1024 * 1024 * 1024;
      }
      $bytes = int($bytes);  # Eliminate possible "fractional" bytes
    }

    @{$memstat_data{$page_type}}{ qw(page_count bytes pct_of_total) } =
      ($page_count, $bytes, $pct_of_total);

    # Clean up undefined "Total"'s percent of total, which is 100%
    $memstat_data{total}->{pct_of_total} = 100;
  }

  return \%memstat_data;
}


__PACKAGE__->meta->make_immutable;

1;

