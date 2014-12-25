package Solaris::Perf::Schema::ResultSet::vmstat;

use 5.18.1;
use warnings;

use parent 'Solaris::Perf::Schema::ResultSet';


__PACKAGE__->load_components(
  'Helper::ResultSet::DateMethods1',
);

#
# These are called from/on vmstat ResultSet objects
#
sub search_host_YMDH {
  $_[0]->search(
    { $_[0]->me . 'host_fk' => $_[1] },
    { columns   => {
        year => { distinct => $_[0]->dt_SQL_pluck({ -ident => '.timestamp' }, 'year') },
      }
    }
  );
}

1;
