#!/usr/bin/perl

use strict;
use warnings;
use Benchmark qw(:all);
our $VERSION = '0.01';

my @ips = map {
    join '.',
        map { int( rand(256) ) }
        1 .. 4
} ( 1 .. 5_000 );

use MaxMind::DB::Reader;
use MaxMind::DB::Reader::XS;

my $file = '/usr/local/share/GeoIP2/city-v6.db';

my $reader = MaxMind::DB::Reader->new( file => $file ) or die;
my $reader_xs = MaxMind::DB::Reader::XS->new( file => $file ) or die;

cmpthese(
    5,
    {
        'reader' => sub {
            eval { $reader->record_for_address($_) } for @ips;
        },
        'reader_xs' => sub {
            eval { $reader_xs->record_for_address($_) } for @ips;
        },
    }
);

__END__

perl -Mblib ./benchmark/bench.pl

          s/iter    reader reader_xs
reader      42.1        --     -100%
reader_xs  0.104    40379%        --
