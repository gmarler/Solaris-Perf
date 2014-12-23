package Solaris::Perf::Web::Controller::vmstat;
use Moose;
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

