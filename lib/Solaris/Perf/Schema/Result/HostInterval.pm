package Solaris::Perf::Schema::Result::HostInterval;

use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('hostinterval');

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
  # Accessor
  'host',
  # Related Class
  'Solaris::Perf::Schema::Result::Host',
  # Relationship
  'host_id'
);

__PACKAGE__->belongs_to(
  # Accessor
  'interval',
  # Related Class
  'Solaris::Perf::Schema::Result::Interval',
  # Relationship
  'interval_id'
);


1;
