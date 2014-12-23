package Solaris::Perf::Schema::Candy;

use 5.18.1;

use warnings;

# VERSION

use parent 'DBIx::Class::Candy';

sub base { 'Solaris::Perf::Schema::Result' }
sub perl_version { 18 }
sub autotable { 1 }

1;

