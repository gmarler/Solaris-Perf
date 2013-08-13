package Solaris::Perf::Schema::Result::FS;

use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('fs');

__PACKAGE__->add_columns(
  id => {
    data_type         => 'integer',
    is_auto_increment => 1,
  },
  mountpoint => {
    data_type         => 'text',
  },
);

__PACKAGE__->set_primary_key('id');

#__PACKAGE__->has_many(
#  hostfs => 'Solaris::Perf::Schema::HostFS', 'host_fs_id'
#);

1;
