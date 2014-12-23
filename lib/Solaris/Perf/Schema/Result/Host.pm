package Solaris::Perf::Schema::Result::Host;
 
# VERSION

use Solaris::Perf::Schema::Candy
  -components => ['InflateColumn::DateTime'];


primary_column host_id => {
  data_type         => 'int',
  is_auto_increment => 1,
};

column name => {
  data_type         => 'varchar',
  size              => '32',
};

column timezone => {
  data_type         => 'varchar',
  size              => '64',
};


has_many 'flamegraphs' => 'Flamegraph', 'flamegraph_id';
has_many 'vmstats'     => 'vmstat',     'vmstat_id';
has_many 'mpstats'     => 'mpstat',     'mpstat_id';

#has_many 'host_zpools' => 'HostZpool', { 'foreign.host_id' => 'self.id' },
#         # TODO: We may need to eliminate the below later...
#         { cascade_delete => 0 }

#many_to_many 'zpools' => 'host_zpools';

1;




####
# __PACKAGE__->has_many(
#   # Name of accessor
#   'host_zpools',
#   # Related Class
#   'Solaris::Perf::Schema::Result::HostZpool',
#   # Relationship
#   { 'foreign.host_id' => 'self.id' },
#   # Attributes
# );
# 
# __PACKAGE__->many_to_many(
#   # Accessor Name
#   zpools
#        # has_many accessor name in this class
#     => 'host_zpools',
#   # Foreign belongs_to() accessor name
#   'zpool'
# );
# 
# ####
# __PACKAGE__->has_many(
#   # Accessor name
#   'host_intervals',
#   # Related Class
#   'Solaris::Perf::Schema::Result::HostInterval',
#   # Relationship
#   { 'foreign.host_id' => 'self.id' },
#   # Attributes
#   # TODO: We may need to eliminate the below later...
#   { cascade_delete => 0 }
# );
# 
# __PACKAGE__->many_to_many(
#   # Accessor name
#   intervals
#     # has_many accessor name in this class
#     => 'host_intervals',
#     # Foreign belongs_to() accessor name
#     'interval'
# );
# 
# 1;

