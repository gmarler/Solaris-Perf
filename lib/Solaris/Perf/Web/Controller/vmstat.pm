package Solaris::Perf::Web::Controller::vmstat;
use Moose;
use List::MoreUtils        qw();
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Solaris::Perf::Web::Controller::vmstat - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub list :Local {
  my ($self, $c) = @_;

  $c->stash(vmstats =>
    [
     $c->model("DB::vmstat")->search({},{ join     => 'host',
                                          prefetch => 'host',
                                        }
     )->all
    ] );

  $c->stash(template => 'vmstat/list.tt');
}


sub svc_base : PathPart('service') Chained('/') CaptureArgs(0) {
  my ($self, $c) = @_;

  # Print a message to the debug log
  $c->log->debug('*** INSIDE svc_base BASE METHOD ***');

  # This works because of our mapping in the config of
  # Solaris::Perf::Web::Schema.pm
  $c->stash(vmstat_rs     => $c->model('DB::vmstat'),
            host_rs       => $c->model('DB::Host'),
           );
}

# Produce list of hosts to choose from that have *any* vmstat data associated
# with them at all
sub svc_vmstat_nohost : PathPart('vmstat') Chained('svc_base')  Args(0) {
  my ($self, $c) = @_;

  # Print a message to the debug log
  $c->log->debug('*** INSIDE svc_vmstat_nohost METHOD ***');

  my $vmstat_rs = $c->stash->{vmstat_rs};

  my $search_rs =
    $vmstat_rs
      ->search_related('host',
                       undef,
                       { 
                         columns => [
                           { hostname => { distinct => "host.name" } },
                           { host_id  => "host.host_id" },
                         ],
                         order_by  => [ 'host.name' ],
                       }
                      );

  my $vmstat_hosts = { };

  while (my $result = $search_rs->next) {
    $DB::single = 1;
    # NOTE: must use get_column here, as there will be no 'hostname' accessor
    #       created
    if (not exists $vmstat_hosts->{$result->get_column('hostname')}) {
      $vmstat_hosts->{$result->get_column('hostname')} = $result->get_column('host_id');
    }
  }

  $c->stash(json_hosts => [ $vmstat_hosts ]);
  $c->forward("View::JSON");
}

sub svc_vmstat : PathPart('vmstat') Chained('svc_base')  CaptureArgs(0) {
  my ($self, $c) = @_;
}

# Years or time ranges for which data is available for a particular host
sub svc_host_time_YMDH : PathPart('host') Chained('svc_vmstat') Args(1) {
  my ($self, $c, $host_id) = @_;

  # Print a message to the debug log
  $c->log->debug('*** INSIDE svc_host METHOD ***');

  my $vmstat_rs = $c->stash->{vmstat_rs};

#  my $year_rs = $vmstat_rs
#                  ->search({ 'host_fk' => $host_id },
#                           { columns   => [
#                               { year => { distinct => \"strftime('%Y',timestamp)" } },
#                             ]
#                           }
#                          );
  my $year_rs = $vmstat_rs->search_host_YMDH( $host_id );

  my $month_rs = $vmstat_rs
                   ->search({ 'host_fk' => $host_id },
                            { columns   => [
                                { month => { distinct => \"strftime('%m',timestamp)" } }
                              ],
                              order_by  => [ 'timestamp' ],
                            }
                           );

  my $day_rs   = $vmstat_rs
                   ->search({ 'host_fk' => $host_id },
                            { columns   => [
                                { day => { distinct => \"strftime('%d',timestamp)" } }
                              ],
                              order_by  => [ 'timestamp' ],
                            }
                           );
 
  my $hour_rs = $vmstat_rs
                  ->search({ 'host_fk' => $host_id },
                           { columns   => [
                               { hour => { distinct => \"strftime('%H',timestamp)" } }
                             ],
                             order_by  => [ 'timestamp' ],
                           }
                          );
  
  $DB::single = 1;

  my $vmstat_host_year  = [ ];
  my $vmstat_host_month = [ ];
  my $vmstat_host_day   = [ ];
  my $vmstat_host_hour  = [ ];

  while (my $result = $year_rs->next) {
    # NOTE: must use get_column here, as there will be no accessor
    #       created
    push @$vmstat_host_year, $result->get_column('year');
  }

  while (my $result = $month_rs->next) {
    # NOTE: must use get_column here, as there will be no accessor
    #       created
    push @$vmstat_host_month, $result->get_column('month');
  }

  while (my $result = $day_rs->next) {
    # NOTE: must use get_column here, as there will be no accessor
    #       created
    push @$vmstat_host_day, $result->get_column('day');
  }


  while (my $result = $hour_rs->next) {
    # NOTE: must use get_column here, as there will be no accessor
    #       created
    push @$vmstat_host_hour, $result->get_column('hour');
  }

  $c->stash( json_years  => $vmstat_host_year  );
  $c->stash( json_months => $vmstat_host_month );
  $c->stash( json_days   => $vmstat_host_day   );
  $c->stash( json_hours  => $vmstat_host_hour  );
  $c->forward("View::JSON");
}



=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Solaris::Perf::Web::Controller::vmstat in vmstat.');
}



=encoding utf8

=head1 AUTHOR

Gordon Marler

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;


