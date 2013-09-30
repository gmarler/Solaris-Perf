package Solaris::Perf::Schema::Result::HostInterval;

use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('hostzpool');

__PACKAGE__->add_columns(
  host_id => {
    data_type         => 'integer',
  },
  interval_id => {
    data_type         => 'integer',
  },
);

__PACKAGE__->set_primary_key('host_id','interval_id');


__PACKAGE__->belongs_to(
  host =>
    'Solaris::Perf::Schema::Result::Host',
    'host_id'
);

__PACKAGE__->belongs_to(
  interval =>
    'Solaris::Perf::Schema::Result::Interval',
    'interval_id'
);


1;
