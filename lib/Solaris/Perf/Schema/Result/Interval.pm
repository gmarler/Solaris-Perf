package Solaris::Perf::Schema::Result::Interval;

use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('interval');

__PACKAGE__->add_columns(
  id => {
    data_type         => 'integer',
    is_auto_increment => 1,
  },
  start => {
    data_type         => 'datetime',
  },
  # TODO: May need 'end' as well, in the end, unless we can deduce it
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
    host => Solaris::Perf::Schema::Host',
    host_id);


