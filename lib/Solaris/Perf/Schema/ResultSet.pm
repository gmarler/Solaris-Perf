package Solaris::Perf::Schema::ResultSet;
 
use strict;
use warnings;
 
use base 'DBIx::Class::ResultSet';
 
__PACKAGE__->load_components(
  'Helper::ResultSet'
  # With the above, are the ones below even needed?
  #'Helper::ResultSet::IgnoreWantarray',
  #'Helper::ResultSet::Me',
);
 
1;
