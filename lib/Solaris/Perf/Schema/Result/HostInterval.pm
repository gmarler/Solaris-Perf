package Solaris::Perf::Schema::Result::HostInterval;

# VERSION

use parent 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(InflateColumn::DateTime Core));
__PACKAGE__->table('hostinterval');

__PACKAGE__->add_columns(
  host_id => {
    data_type         => 'integer',
  },
  interval_id => {
    data_type         => 'integer',
  },
);

#
# NOTE: Might want to make a separate primary key, rather
#       than a composite one.  That way, we don't have to 
#       store 2 id values in all rows that belong to each
#       HostInterval.
__PACKAGE__->set_primary_key('host_id','interval_id');


# __PACKAGE__->belongs_to(
#   # Accessor
#   'host',
#   # Related Class
#   'Solaris::Perf::Schema::Result::Host',
#   # Relationship
#   'host_id'
# );
# 
# __PACKAGE__->belongs_to(
#   # Accessor
#   'interval',
#   # Related Class
#   'Solaris::Perf::Schema::Result::Interval',
#   # Relationship
#   'interval_id'
# );
# 
# __PACKAGE__->has_many(
#   # Name of accessor
#   'mpstats',
#   # Related Class
#   'Solaris::Perf::Schema::Result::mpstat',
#   # Relationship
#   { 'foreign.interval_id' => 'self.interval_id',
#     'foreign.host_id'     => 'self.host_id' },
#   # Attributes
#   # TODO: We may need to eliminate the below later...
#   # { cascade_delete => 0 }
# );


1;

