
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

print "mmdb=".$iut->_mmdb."\n";

my $metadata = $iut->_raw_metadata($iut->_mmdb);
print Dumper $metadata;

}

print "Done\n";

