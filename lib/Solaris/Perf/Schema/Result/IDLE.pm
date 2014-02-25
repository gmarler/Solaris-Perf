package Solaris::Perf::Schema::Result::IDLE;

use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(Core));
__PACKAGE__->table('idle');

__PACKAGE__->add_columns(
  id => {
    data_type         => 'integer',
    is_auto_increment => 1,
  },
  # Composite keys from HostInterval
  interval_id => {
    data_type         => 'integer',
  },
  host_id => {
    data_type         => 'integer',
  },
);

__PACKAGE__->set_primary_key('id');


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
