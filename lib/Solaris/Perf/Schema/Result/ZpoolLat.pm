package Solaris::Perf::Schema::Result::ZpoolLat;

use strict;
use warnings;

use parent 'DBIx::Class::Core';

#__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('zpoollat');

__PACKAGE__->add_columns(
  id => {
    data_type         => 'integer',
    is_auto_increment => 1,
  },
  interval => {
    data_type         => 'integer',
  },
  bucket => {
    data_type         => 'integer',
  },
  count => {
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
