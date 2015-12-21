use strict;
use warnings;
use autodie;

use Test::More;

use MaxMind::DB::Reader::XS;

## no critic (Subroutines::ProhibitCallsToUnexportedSubs)
ok(
    1,
    'libmaxminddb version is '
        . MaxMind::DB::Reader::XS::libmaxminddb_version()
);

done_testing();
