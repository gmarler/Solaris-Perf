use strict;
use warnings;

use DBIx::Class::Migration::RunScript;
use DateTime qw();

migrate {
  my $memstat_rs = shift->schema->resultset('Memstat');

  # Based on this output from memstat-v1c.sh
  # 1431921752
  # Page Summary                 Pages             Bytes  %Tot
  # ----------------- ----------------  ----------------  ----
  # Kernel                     8241546             62.8G    6%
  # Guest                            0                 0    0%
  # ZFS Metadata               2234105             17.0G    2%
  # ZFS File Data             57382025            437.7G   43%
  # Anon                      17565900            134.0G   13%
  # Exec and libs             24925096            190.1G   19%
  # Page cache                 1525605             11.6G    1%
  # Free (cachelist)           1466805             11.1G    1%
  # Free (freelist)           20745574            158.2G   15%
  # Total                    134086656             1023G
  
  $memstat_rs->create(
    {
      datetime       => DateTime->from_epoch(epoch => 1431921752),
      kernel         => 67430986547,
      guest          => 0,
      zfs_metadata   => 18253611008,
      zfs_file_data  => 469976796364,
      anon           => 158913789952,
      exec_and_libs  => 204118320742,
      page_cache     => 12455405158,
      free_cachelist => 11918534246,
      free_freelist  => 169865956556,
      total          => 1098437885952,
    });

};
