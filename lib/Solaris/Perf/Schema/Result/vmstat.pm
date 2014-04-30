package Solaris::Perf::Schema::Result::vmstat;

use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);

__PACKAGE__->table('vmstat');

__PACKAGE__->add_columns(
  'vmstat_id' => {
    data_type   => 'integer',
  },
  'timestamp' => {
    data_type   => 'datetime',
    is_nullable => 0,
  },
  # CPU
  'cpu_user' => {
    data_type   => 'smallint',
  },
  'cpu_sys' => {
    data_type   => 'smallint',
  },
  'cpu_idle' => {
    data_type   => 'smallint',
  },
);

__PACKAGE__->set_primary_key('vmstat_id');

1;
