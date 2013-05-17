#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

our $VERSION = '0.01';

use MaxMind::DB::Reader::XS;
use Data::Dumper;

my $x18181818 = {
    'country' => {
        'iso_code' => 'US',
        'names'    => {
            'zh-CN' => "\x{7f8e}\x{56fd}",
            'en'    => 'United States',
            'ja' =>
                "\x{30a2}\x{30e1}\x{30ea}\x{30ab}\x{5408}\x{8846}\x{56fd}",
            'ru' => "\x{421}\x{428}\x{410}"
        },
        'geoname_id' => 6252001
    },
    'subdivisions' => [
        {
            'iso_code' => 'NY',
            'names'    => {
                'zh-CN' => "\x{7ebd}\x{7ea6}\x{5dde}",
                'en'    => 'New York',
                'ja' =>
                    "\x{30cb}\x{30e5}\x{30fc}\x{30e8}\x{30fc}\x{30af}\x{5dde}",
                'ru' => "\x{41d}\x{44c}\x{44e}-\x{419}\x{43e}\x{440}\x{43a}"
            },
            'geoname_id' => 5128638
        }
    ],
    'location' => {
        'longitude'  => '-73.7752',
        'latitude'   => '40.6763',
        'time_zone'  => 'America/New_York',
        'metro_code' => '501'
    },
    'postal' => { 'code' => '11434' },
    'city'   => {
        'names'      => { 'en' => 'Jamaica' },
        'geoname_id' => 5122520
    },
    'continent' => {
        'names' => {
            'zh-CN' => "\x{5317}\x{7f8e}\x{6d32}",
            'en'    => 'North America',
            'ja'    => "\x{5317}\x{30a2}\x{30e1}\x{30ea}\x{30ab}",
            'ru' =>
                "\x{421}\x{435}\x{432}\x{435}\x{440}\x{43d}\x{430}\x{44f} \x{410}\x{43c}\x{435}\x{440}\x{438}\x{43a}\x{430}"
        },
        'continent_code' => 'NA',
        'geoname_id'     => 6255149
    },
    'registered_country' => {
        'iso_code' => 'US',
        'names'    => {
            'zh-CN' => "\x{7f8e}\x{56fd}",
            'en'    => 'United States',
            'ja' =>
                "\x{30a2}\x{30e1}\x{30ea}\x{30ab}\x{5408}\x{8846}\x{56fd}",
            'ru' => "\x{421}\x{428}\x{410}"
        },
        'geoname_id' => 6252001
    },
    'traits' => {
        'cellular'    => 1,
        'is_military' => 0
    }
};

use FindBin qw/$Bin/;

my $mmdb = MaxMind::DB::Reader::XS->open( "$Bin/data/v4-28.mmdb", 2 );

is( MaxMind::DB::Reader::XS->lib_version, '0.2', "CAPI Version is 0.2" );
is(
    MaxMind::DB::Reader::XS->lib_version, '0.2',
    "lib_version works as static member function"
);
is( $mmdb->lib_version, '0.2', "lib_version works as member function" );

my $meta = $mmdb->metadata;

for (
    [ 'ip_version'                  => 4, ],
    [ 'binary_format_minor_version' => 0, ],
    [ 'node_count'                  => 24, ],
    [ 'database_type'               => 'Test', ],
    [ 'record_size'                 => 28, ],
    [ 'binary_format_major_version' => 2 ],
    ) {
    is( $meta->{ $_->[0] }, $_->[1], "\$meta->{$_->[0]} is $_->[1]" );
}

# ignore upper 32bit and avoid issues on 32bit perl
my ($secs) = unpack xxxxN => $meta->{build_epoch};
is(
    localtime($secs), q[Fri May  3 19:10:14 2013],
    "DB built time was Fri May  3 19:10:14 2013"
);

is( $meta->{description}{en}, 'Test Database', 'description match' );
is( "@{$meta->{languages}}", 'en ja ru zh-CN', 'DB contains en ja ru zh-CN' );

my $result = $mmdb->lookup_by_ip('24.24.24.24');
is_deeply( $result, $x18181818, "Data for 24.24.24.24 match" );

is( utf8::is_utf8($result->{registered_country}{names}{ja}), 1, "utf8 flag is set for names/ja");
ok( !utf8::is_utf8($result->{registered_country}{names}{us}), "utf8 flag is NOT set for names/us");

done_testing();

__END__
