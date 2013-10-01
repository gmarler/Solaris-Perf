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
  # Name of accessor
  'host_zpools',
  # Related Class
  'Solaris::Perf::Schema::Result::HostZpool',
  # Relationship
  { 'foreign.host_id' => 'self.id' },
  # Attributes
  # TODO: We may need to eliminate the below later...
  { cascade_delete => 0 }
);

__PACKAGE__->many_to_many(
  # Accessor Name
  zpools
       # has_many accessor name in this class
    => 'host_zpools',
  # Foreign belongs_to() accessor name
  'zpool'
);

####
__PACKAGE__->has_many(
  # Accessor name
  'host_intervals',
  # Related Class
  'Solaris::Perf::Schema::Result::HostInterval',
  # Relationship
  { 'foreign.host_id' => 'self.id' },
  # Attributes
  # TODO: We may need to eliminate the below later...
  { cascade_delete => 0 }
);

__PACKAGE__->many_to_many(
  # Accessor name
  intervals
    # has_many accessor name in this class
    => 'host_intervals',
    # Foreign belongs_to() accessor name
    'interval'
);

1;
