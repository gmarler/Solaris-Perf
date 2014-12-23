package Solaris::Perf::Schema::Result::HostZpool;

use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('hostzpool');

__PACKAGE__->add_columns(
  host_id => {
    data_type         => 'integer',
  },
  zpool_id => {
    data_type         => 'integer',
  },
);

__PACKAGE__->set_primary_key('host_id', 'zpool_id');


# __PACKAGE__->belongs_to(
#   # Accessor
#   'host',
#   # Related Class
#   'Solaris::Perf::Schema::Result::Host',
#   # Relationship
#   { 'foreign.id' => 'self.host_id' }
# );
# 
# __PACKAGE__->belongs_to(
#   # Accessor
#   'zpool',
#   # Related Class
#   'Solaris::Perf::Schema::Result::Zpool',
#   # Relationship
#   { 'foreign.id' => 'self.zpool_id' }
# );


1;

