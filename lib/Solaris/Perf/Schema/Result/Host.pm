package Solaris::Perf::Schema::Result::Host;

use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('host');

__PACKAGE__->add_columns(
  id => {
    data_type         => 'integer',
    is_auto_increment => 1,
  },
  name => {
    data_type         => 'text',
  },
);

__PACKAGE__->set_primary_key('id');

#__PACKAGE__->has_many(
#  fs => 'Solaris::Perf::Schema::Result::FS', 'host_id'
#);

__PACKAGE__->has_many(
  zpools =>
    'Solaris::Perf::Schema::Result::Zpool',
);

__PACKAGE__->has_many(
  intervals =>
    'Solaris::Perf::Schema::Result::Interval',
);

1;
