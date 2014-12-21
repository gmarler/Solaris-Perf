package Solaris::Perf::Schema::MigrationScript;

use Moose;
use Solaris::Perf::Web;

extends 'DBIx::Class::Migration::Script';

sub defaults {
  schema => Solaris::Perf::Web->model('DB')->schema,
}

__PACKAGE__->meta->make_immutable;
__PACKAGE__->run_if_script;

