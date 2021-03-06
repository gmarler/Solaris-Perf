use Test::Class::Moose::Load 't/lib';
use Test::Class::Moose::Runner;

# Invocation examples:
#
# Everything:
#   prove -lv t/tests.t
# Individual test:
#   prove -lv t/tests.t :: TF::Solaris::PerfParser::ZpoolLatency
#
my $test_suite = Test::Class::Moose::Runner->new(
  show_timing  => 0,
  randomize    => 0,
  statistics   => 1,
  test_classes => \@ARGV,
);

$test_suite->runtests;

my $report = $test_suite->test_report;

