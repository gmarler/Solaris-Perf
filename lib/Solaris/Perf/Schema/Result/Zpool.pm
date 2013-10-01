package Solaris::Perf::Schema::Result::Zpool;

use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('zpool');

__PACKAGE__->add_columns(
  id => {
    data_type         => 'integer',
    is_auto_increment => 1,
  },
  zpool_name => {
    data_type         => 'text',
  },
);

__PACKAGE__->set_primary_key('id');


1;
