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


####
__PACKAGE__->has_many(
  host_zpools =>
    'Solaris::Perf::Schema::Result::HostZpool',
    'host_id',
    # TODO: We may need to eliminate the below later...
    { cascade_delete => 0 }
);

__PACKAGE__->many_to_many(
  zpools => 'host_zpools',
  'zpool_id'
);

####
__PACKAGE__->has_many(
  host_intervals =>
    'Solaris::Perf::Schema::Result::HostInterval',
    'host_id',
    # TODO: We may need to eliminate the below later...
    { cascade_delete => 0 }
);

__PACKAGE__->many_to_many(
  intervals => 'host_intervals',
    'interval_id'
);

1;
