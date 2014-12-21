package Solaris::PerfParser::vmstat;

# VERSION

use Moose;
use namespace::autoclean;

with 'Solaris::PerfParser';

sub _build_dt_regex {
  # this vmstat output is configured to receive the internal representation of
  # time, per time(2), which are epoch secs
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

  my (%vmstat_data);

  # NOTE: Need to test for this particular issue:
  # The epoch secs can be immediately followed by the header, like so:
  # 1418101214
  # kthr      memory            page            disk          faults      cpu
  # r b w   swap  free  re  mf pi po fr de sr s0 s1 s3 s4   in   sy   cs us sy id
  # <actual data>
  my $vmstat_regex =
    qr{^ (?: \s+? (?<kthr_runq>(?:kthr|r)) [^\n]+ \n |   # vmstat data headers
             \s+? (?<kthr_runq>\d+) \s+ (?<kthr_blocked>\d+) \s+
                  (?<kthr_swapped>\d+) \s+
             (?<swap_avail>\d+) \s+ (?<free_list>\d+) \s+
             (?<page_reclaims>\d+) \s+ (?<minor_faults>\d+) \s+
             (?<page_in_KB>\d+) \s+ (?<page_out_KB>\d+) \s+
             (?<freed_KB>\d+) \s+ (?<shortfall_KB>\d+) \s+
             (?<scan_rate>\d+) \s+
             (?<s0>\d+) \s+ (?<s1>\d+) \s+ (?<s2>\d+) \s+ (?<s3>\d+) \s+
             (?<interrupts>\d+) \s+ (?<syscalls>\d+) \s+
             (?<context_switches>\d+) \s+ (?<user>\d+) \s+
             (?<sys>\d+) \s+ (?<idle>\d+)
             \n
         )
      }smx;

  my @keys = qw(kthr_runq  kthr_blocked kthr_swapped swap_avail
                free_list page_reclaims minor_faults page_in_KB
                page_out_KB freed_KB shortfall_KB scan_rate
                s0 s1 s2 s3 interrupts syscalls context_switches
                user sys idle );

  # We added 'g' here to get them all, one by one
  # There's only one line per interval though, so not much to do.
  while ($data =~ m{ $vmstat_regex }gsmx ) {
    # Skip headers
    next if ($+{kthr_runq} =~ m{^(?:kthr|r)$} );

    my %href = map { $_ => $+{$_} } @keys;

    # push @{$vmstat_data{'vm_data'}}, \%href;
    $vmstat_data{'vm_data'} = \%href;
  }

  return \%vmstat_data;
}




__PACKAGE__->meta->make_immutable;

1;

