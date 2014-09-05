use strict;
use warnings;

use Test::LeakTrace;
use Test::More 0.88;

use MaxMind::DB::Reader 0.050000;

my $reader = MaxMind::DB::Reader->new(
    file => 'maxmind-db/test-data/MaxMind-DB-test-ipv4-24.mmdb' );

my ( $record, $ref_to_record, $copy_of_record );
no_leaks_ok {
    ( $record, $ref_to_record, $copy_of_record ) = get_record();
}
'no leaks when getting a record';

is_deeply(
    $record,
    { ip => '1.1.1.1' },
    'got expected data in record'
);

is_deeply(
    $ref_to_record->{record},
    { ip => '1.1.1.1' },
    'got expected data in ref to record'
);

is_deeply(
    $copy_of_record->{copy},
    { ip => '1.1.1.1' },
    'got expected data in copy of record'
);

no_leaks_ok {
    undef $reader;
}
'no leaks when destroying reader object';

done_testing();

sub get_record {
    my $record = $reader->record_for_address('1.1.1.1');

    return (
        $record,
        { record => $record },
        { copy   => { %{$record} } },
    );
}
