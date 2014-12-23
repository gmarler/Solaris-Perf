package Solaris::Perf::Schema::Result::Flamegraph;

# VERSION

use Solaris::Perf::Schema::Candy
  -components => ['InflateColumn::DateTime'];


primary_column flamegraph_id => {
  data_type           => 'int',
  is_auto_increment   => 1,
};

column creation => {
  data_type           => 'datetime',
  time_zone           => 'UTC',
};

column begin => {
  data_type           => 'datetime',
  time_zone           => 'UTC',
};

column end => {
  data_type           => 'datetime',
  time_zone           => 'UTC',
};

column host_fk => {
  data_type           => 'int',
};

column stacks => {
  data_type           => 'blob',
};

column svg => {
  data_type           => 'blob',
  is_nullable         => 1,
};

belongs_to host => 'Solaris::Perf::Schema::Result::Host',
                   {'foreign.host_id'=>'self.host_fk'};

1;


