use strict;
use warnings;

use Test::Fatal;
use Test::More;

use lib 't/lib';
use Test::MaxMind::DB::Reader;

use MaxMind::DB::Reader;

{    # Test broken doubles
    my $reader
        = MaxMind::DB::Reader->new( file =>
            'maxmind-db/test-data/GeoIP2-City-Test-Broken-Double-Format.mmdb'
        );
    like(
        exception { $reader->record_for_address('2001:220::') },
        qr/got entry data error looking up "2001:220::" - The MaxMind DB file's data section contains bad data \(unknown data type or corrupt data\)/,
        'got expected error for broken doubles'
    );
}

{    # test broken search tree pointer
    my $reader = MaxMind::DB::Reader->new( file =>
            'maxmind-db/test-data/MaxMind-DB-test-broken-pointers-24.mmdb' );
    like(
        exception { $reader->record_for_address('1.1.1.32') },
        qr/error looking up IP address "1.1.1.32" - The MaxMind DB file's search tree is corrupt at/,
        'received expected exception with broken search tree pointer'
    );
}

{    # test broken data pointer
    my $reader = MaxMind::DB::Reader->new( file =>
            'maxmind-db/test-data/MaxMind-DB-test-broken-pointers-24.mmdb' );
    like(
        exception { $reader->record_for_address('1.1.1.16') },
        qr/got entry data error looking up "1.1.1.16" - The MaxMind DB file's data section contains bad data \(unknown data type or corrupt data\)/,
        'received expected exception with broken data pointer'
        );
}

{    # test non-database
    my $reader = MaxMind::DB::Reader->new( file => 'Changes' );

    like(
        exception { $reader->record_for_address('1.1.1.16') },
        qr/error opening database file "Changes"- The MaxMind DB file is in a format this library can't handle \(unknown record size or binary format version\)/,
        'expected exception with unknown file type'
    );
}

done_testing();
