package Solaris::Perf::Schema::Result::IOAction;

use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->table('ioaction');

__PACKAGE__->add_columns(
  id => {
    data_type         => 'integer',
    is_auto_increment => 1,
  },
  # I/O Action name, i.e.: read/write/pread/pwrite/
  #                        readv/writev/...
  action => {
    data_type         => 'text',
  },
);

__PACKAGE__->set_primary_key('id');


#__PACKAGE__->has_many(
#  zpoollats =>
#    'Solaris::Perf::Schema::Result::ZpoolLat',
#);

1;
