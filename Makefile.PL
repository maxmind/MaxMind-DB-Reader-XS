use 5.012000;
use ExtUtils::MakeMaker;

require DynaLoader;

my $maxminddb_libpath = '';
my $maxminddb_incpath = '';

my @replacement_args;

my %config;

while ( $_ = shift ) {
    my ( $key, $val ) = split( /=/, $_, 2 );
    $config{$key} = $val;
}

unless ( $config{LIBS} ) {

    # currently we check only for the C Library version if it is in a
    # standard place
    my $maxminddb_version = 0;
    my $clib          = DynaLoader::dl_findfile('maxminddb');
    my $found         = $clib ? 1 : 0;
    if ($clib) {

        my $lib = DynaLoader::dl_load_file( $clib, 0 );
        if ($lib) {
            for (
                [
                    0001,
                    'MMDB_last_netmask'
                ],
                ) {
                $maxminddb_version = $_->[0]
                    if DynaLoader::dl_find_symbol(
                    $lib,
                    $_->[1]
                    );
            }
        }
    }
}

if ( $config{LIBS} !~ /\-lmaxminddb\b/ ) {
    $config{LIBS} .= ' -lmaxminddb';
}

if ( $CONFIG{INC} ) {
    $config{INC} .= ' -I.';
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME => 'MaxMind::DB::Reader::XS',
    dist => { COMPRESS => 'gzip', SUFFIX => '.gz' },

    VERSION_FROM => 'lib/MaxMind/DB/Reader/XS.pm', # finds $VERSION
    PREREQ_PM    => {},                            # e.g., Module::Name => 1.1
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
            (
            ABSTRACT_FROM =>
                'lib/MaxMind/DB/Reader/XS.pm', # retrieve abstract from module
            AUTHOR => 'bz <bzentner@maxmind.com>'
            )
        : ()
    ),
    LIBS   => ['-lmaxminddb'],    # e.g., '-lm'
    DEFINE => '-DPERL_EXT',       # otherwise 'cxinc' isn't defined
    INC    => '-I.',              # e.g., '-I. -I/usr/include/other'
    %config,
);
