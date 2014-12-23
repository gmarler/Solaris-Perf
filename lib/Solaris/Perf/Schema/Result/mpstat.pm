package Solaris::Perf::Schema::Result::mpstat;

# VERSION

use Solaris::Perf::Schema::Candy
  -components => ['InflateColumn::DateTime'];


primary_column mpstat_id => {
  data_type         => 'int',
  is_auto_increment => 1,
};

column host_fk => {
  data_type         => 'integer',
};

# Composite keys from HostInterval
# column host_id => {
#   data_type         => 'integer',
# };
# 
# column interval_id => {
#   data_type         => 'integer',
# };

# Actual fields for this row type
column cpu => {
    data_type         => 'integer',
};

# minf
# mjf

column xcal => {
    data_type         => 'integer',
};

# intr
# ithr
# csw
# icsw
# migr
# smtx
# srw
# syscl

column usr => {
   data_type         => 'integer',
};

column sys => {
    data_type         => 'integer',
};

# wt - always ignore this - it's always 0 nowadays

column idl => {
    data_type         => 'integer',
};

# __PACKAGE__->belongs_to(
#   # Accessor
#   'host_interval',
#   # Related Class
#   'Solaris::Perf::Schema::Result::HostInterval',
#   # Our Foreign Key Column OR custom join expression
#   # We might want to make HostInterval have it's own unique PK, rather
#   # than a composite one
#   {
#     'foreign.host_id'     => 'self.host_id',
#     'foreign.interval_id' => 'self.interval_id'
#   }
# );

belongs_to host => 'Solaris::Perf::Schema::Result::Host',
                   { 'foreign.host_id' => 'self.host_fk' };

1;

