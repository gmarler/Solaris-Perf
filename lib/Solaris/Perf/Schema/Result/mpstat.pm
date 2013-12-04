package Solaris::Perf::Schema::Result::mpstat;

use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(Core));
__PACKAGE__->table('mpstat');

__PACKAGE__->add_columns(
  id => {
    data_type         => 'integer',
    is_auto_increment => 1,
  },
  # Composite keys from HostInterval
  host_id => {
    data_type         => 'integer',
  },
  interval_id => {
    data_type         => 'integer',
  },
  # Actual fields for this row type
  cpu => {
    data_type         => 'integer',
  },
  # minf
  # mjf
  xcal => {
    data_type         => 'integer',
  },
  # intr
  # ithr
  # csw
  # icsw
  # migr
  # smtx
  # srw
  # syscl
  usr => {
    data_type         => 'integer',
  },
  sys => {
    data_type         => 'integer',
  },
  # wt - always ignore this - it's always 0 nowadays
  idl => {
    data_type         => 'integer',
  },
);

__PACKAGE__->set_primary_key('id');

#__PACKAGE__->belongs_to(
#    interval =>
#      'Solaris::Perf::Schema::Result::Interval',
#    );
#
#__PACKAGE__->belongs_to(
#    ioaction =>
#      'Solaris::Perf::Schema::Result::IOAction',
#    );

__PACKAGE__->belongs_to(
  # Accessor
  'host_interval',
  # Related Class
  'Solaris::Perf::Schema::Result::HostInterval',
  # Our Foreign Key Column OR custom join expression
  # We might want to make HostInterval have it's own unique PK, rather
  # than a composite one
  {
    'foreign.host_id'     => 'self.host_id',
    'foreign.interval_id' => 'self.interval_id'
  }
);

1;
