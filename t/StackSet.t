use Test::Most tests => 1;
use IO::All;
use Data::Dumper;
use Cpanel::JSON::XS;

BEGIN {
  use_ok 'Solaris::Perf::StackSet';
}

my $fh = IO::All->new("/tmp/junk");

my $ss = Solaris::Perf::StackSet->new;

$ss->collapseStack($fh);

# diag Dumper($ss->ss_stacks);
#
$ss->create_tree;

my $tree = $ss->tree;

my $json_text = Cpanel::JSON::XS->new->utf8->pretty->encode($tree);

diag $json_text;

#diag Dumper($ss->tree);


