{
  'name'                     =>  'Solaris::Perf::Web',
  # Allow use of '/' (URI Escaped as %2F) to be used as URI component
  # See this variable in https://metacpan.org/pod/Catalyst for details
  'use_request_uri_for_path' => 1,

  'Solaris::Perf::Web::Model::DB' => {
    traits               => [ 'FromMigration' ],
    schema_class         => 'Solaris::Perf::Schema',
    extra_migration_args => {
      db_sandbox_builder_class => 'DBIx::Class::Migration::TempDirSandboxBuilder',
      # db_sandbox_class         => 'DBIx::Class::Migration::PostgreSQLSandbox',
    },
    install_if_needed    => {
      default_fixture_sets     => [ 'all_tables' ],
    },
  },

  'psgi_middleware', [
    'Debug' => {
      panels => [
            'Memory',
            'Timer',
            'CatalystLog',
            'CatalystStash',
            'DBIC::QueryLog',
      ]
    },
  ],
};


# <psgi_middleware>
#   <Debug>
#     <panels>
#       Memory
#       Timer
#       CatalystLog
#       CatalystStash
#     </panels>
#   </Debug>
# </psgi_middleware>

