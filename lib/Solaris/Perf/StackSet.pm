package Solaris::Perf::StackSet;

# VERSION

use Moose;
use List::Util qw(reduce);

use namespace::autoclean;

# maps serialized stack -> count
has ss_counts => (
  is   => 'rw',
  isa  => "HashRef",
  default => sub {
    return {};
  }
);

# maps serialized stack -> stack
has ss_stacks => (
  is   => 'rw',
  isa  => "HashRef",
  default => sub {
    return {};
  }
);

# Organized Tree of stack data
has tree => (
  is   => 'rw',
  isa  => "HashRef",
  default => sub {
    return {};
  }
);


sub collapseStack {
  my ($self,$fh) = @_;
  my (%collapsed,$collapsed);
  my $headerlines = 3;

  my $nr = 0;
  my @stack;

  while (my $line = $fh->getline) {
    next if $nr++ < $headerlines;
    chomp($line);

    if ($line =~ m/^\s*(\d+)+$/) {
      #$collapsed{join(";", @stack)} = $1;
      $self->addStack([@stack],$1);
      @stack = ();
      next;
    }

    next if ($line =~ m/^\s*$/);

    my $frame = $line;
    $frame =~ s/^\s*//;
    $frame =~ s/\+[^+]*$//;
    # Remove arguments from C++ function names.
    $frame =~ s/(..)[(<].*/$1/;
    $frame = "-" if $frame eq "";
    unshift @stack, $frame;
  }
}

sub addStack {
  my ($self,$stack_aref,$count) = @_;

  my $ss_counts = $self->ss_counts;
  my $ss_stacks = $self->ss_stacks;

  my $key = join ',', @$stack_aref;

  if (not exists($ss_counts->{$key})) {
    $ss_counts->{$key} = 0;
    $ss_stacks->{$key} = $stack_aref;
  }

  $ss_counts->{$key} += $count;

  $self->ss_counts($ss_counts);
  $self->ss_stacks($ss_stacks);
}

#
# Iterates all stacks in alphabetical order by full stack
#
sub eachStackByStack {
  my ($self, $callback) = @_;

  my %ss_stacks = %{$self->ss_stacks};
  my %ss_counts = %{$self->ss_counts};
  my $tree      = $self->tree;

  foreach my $key (sort keys %ss_stacks) {
    $callback->($tree,$ss_stacks{$key},$ss_counts{$key});
  }
}

#
# Create tree when asked
#
sub create_tree {
  my ($self) = shift;
  my $tree;

  $self->eachStackByStack(\&create_subtree);

  $tree = $self->tree;
  my $overall_svTotal =
  reduce { $a + $b }
  map { $tree->{$_}->{svTotal} }
  keys %{$tree};
  $tree->{''} = {
    svUnique   => 0,
    svTotal    => 0,
    svChildren => $tree,
  };
}

sub create_subtree {
  my ($tree, $frames, $count) = @_;
  my $subtree = $tree;
  my $node;

  for (my $i = 0; $i < scalar(@{$frames}); $i++) {
    if (not exists($subtree->{$frames->[$i]})) {
      $subtree->{$frames->[$i]} = {
        svUnique   => 0,
        svTotal    => 0,
        svChildren => {},
      }
    }
    $node = $subtree->{$frames->[$i]};
    $node->{svTotal} += $count;
    $subtree = $node->{svChildren};
  }
}

no Moose;

1;
