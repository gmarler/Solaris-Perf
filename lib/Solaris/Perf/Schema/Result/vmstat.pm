package Solaris::Perf::Schema::Result::vmstat;

# VERSION

use Solaris::Perf::Schema::Candy
  -components => ['InflateColumn::DateTime'];

primary_column vmstat_id => {
  data_type           => 'int',
  is_auto_increment   => 1,
};

column host_fk   => {
  data_type           => 'int',
};

column timestamp => {
  data_type           => 'datetime',
  time_zone           => 'UTC',
};

column free_list => {
  data_type           => 'int',
};

column scan_rate => {
  data_type           => 'int',
};

column idle => {
  data_type           => 'int',
};


belongs_to host => 'Solaris::Perf::Schema::Result::Host',
                   {'foreign.host_id'=>'self.host_fk'};

1;

