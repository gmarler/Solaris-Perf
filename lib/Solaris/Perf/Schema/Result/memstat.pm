package Solaris::Perf::Schema::Result::memstat;

# VERSION

use Solaris::Perf::Schema::Candy
  -components => ['InflateColumn::DateTime'];


primary_column memstat_id => {
  data_type         => 'int',
  is_auto_increment => 1,
};

#column host_fk => {
#  data_type         => 'integer',
#};

# Actual fields for this row type
# NOTE: Normalizing all sizes to bytes

column datetime => {
  data_type           => 'datetime',
  time_zone           => 'UTC',
};

column kernel => {
    data_type         => 'integer',
};

column guest => {
    data_type         => 'integer',
};

column zfs_metadata => {
   data_type         => 'integer',
};

column zfs_file_data => {
    data_type         => 'integer',
};

column anon => {
    data_type         => 'integer',
};

column exec_and_libs => {
    data_type         => 'integer',
};

column page_cache => {
    data_type         => 'integer',
};

column free_cachelist => {
    data_type         => 'integer',
};

column free_freelist => {
    data_type         => 'integer',
};

column total => {
    data_type         => 'integer',
};

  #belongs_to host => 'Solaris::Perf::Schema::Result::Host',
#                   { 'foreign.host_id' => 'self.host_fk' };

1;

