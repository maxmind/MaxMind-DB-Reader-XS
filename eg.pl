
use strict;
use warnings;
use Data::Dumper;
use lib 'lib';
use lib 'blib/arch';

use MaxMind::DB::Reader::XS;

{


my $iut = MaxMind::DB::Reader::XS->new(
    file => 'maxmind-db/test-data/MaxMind-DB-test-ipv4-32.mmdb',
);

print Dumper $iut->_raw_metadata($iut->_mmdb);

print Dumper $iut->_data_for_address("1.1.1.1");

}

print "Done\n";

