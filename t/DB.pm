package t::DB;

use strict;
use warnings;

use Try::Tiny;
use DBICx::TestDatabase;
use Solaris::Perf ();
use Test::WWW::Mechanize::Catalyst 'Solaris::Perf';

my $schema;

sub make_schema { $schema ||= DBICx::TestDatabase->new( shift ) }

sub import
{
  my $self        = shift;
  my $appname     = 'Solaris::Perf';
  my $schema_name = $appname . '::Schema';
  my $schema      = make_schema( $schema_name );
}

1;
