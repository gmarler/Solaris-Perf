use strict;
use warnings;

use Solaris::Perf;

my $app = Solaris::Perf->apply_default_middlewares(Solaris::Perf->psgi_app);
$app;

