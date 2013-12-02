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
  interval => {
    data_type         => 'integer',
  },
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

1;
