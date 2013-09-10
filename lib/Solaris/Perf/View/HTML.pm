package Solaris::Perf::View::HTML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
);

=head1 NAME

Solaris::Perf::View::HTML - TT View for Solaris::Perf

=head1 DESCRIPTION

TT View for Solaris::Perf.

=head1 SEE ALSO

L<Solaris::Perf>

=head1 AUTHOR

Gordon Marler

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
