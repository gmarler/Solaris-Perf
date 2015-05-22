package Solaris::Perf::Schema::Result::Memstat;

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
    data_type         => 'bigint',
};

column guest => {
    data_type         => 'bigint',
};

column zfs_metadata => {
   data_type         => 'bigint',
};

column zfs_file_data => {
    data_type         => 'bigint',
};

column anon => {
    data_type         => 'bigint',
};

column exec_and_libs => {
    data_type         => 'bigint',
};

column page_cache => {
    data_type         => 'bigint',
};

column free_cachelist => {
    data_type         => 'bigint',
};

column free_freelist => {
    data_type         => 'bigint',
};

column total => {
    data_type         => 'bigint',
};

  #belongs_to host => 'Solaris::Perf::Schema::Result::Host',
#                   { 'foreign.host_id' => 'self.host_fk' };

1;

