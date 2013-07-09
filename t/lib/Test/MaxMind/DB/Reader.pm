package Test::MaxMind::DB::Reader;

use strict;
use warnings;

use MaxMind::DB::Reader::XS;

$ENV{MAXMIND_DB_READER_IMPLEMENTATION} = 'XS';

require MaxMind::DB::Reader;

1;
