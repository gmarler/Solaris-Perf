use strict;
use warnings;

use Solaris::Perf::Web;

my $app = Solaris::Perf::Web->apply_default_middlewares(Solaris::Perf::Web->psgi_app);
$app;


