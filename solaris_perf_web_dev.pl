{
  'name'                     =>  'Solaris::Perf::Web',

  # This is our default view, unless specified otherwise in individual
  # controller methods
  default_view               => 'HTML',

  # Only expose variables in the stash that start with json_ when using the
  # JSON view
  'View::JSON' => {
    expose_stash         => qr/^json_/,
  },

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

  # We do this so we can still serve HTML files directly (we leave html
  # out of the list below)
  'Plugin::Static::Simple' => {
    ignore_extensions => [ qw/tmpl tt tt2 xhtml/ ],
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
