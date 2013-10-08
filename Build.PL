use strict;
use warnings;

use lib 'inc';

use Config::AutoConf;
use Module::Build;

unless ( Config::AutoConf->check_lib('maxminddb', 'MMDB_lookup_string') ) {
    warn <<'EOF';

  It looks like you either don't have libmaxminddb installed or you have an
  older version installed that doesn't define the MMDB_lookup_string
  symbol. Please upgrade your libmaxminddb installation.

EOF

    exit 1;
}

unless ( Config::AutoConf->check_header('maxminddb_config.h') ) {
    warn <<'EOF';

  It looks like the version of libmaxminddb you installed did not provide a
  maxminddb_config.h header. Please upgrade your libmaxminddb installation.

EOF

    exit 1;
}

unless (
    Config::AutoConf->check_type('unsigned __int128')
    || Config::AutoConf->check_type(
        'unsigned int __attribute__ ((__mode__ (TI)))')
    ) {

    warn <<'EOF';

  It looks like your compiler doesn't support the "unsigned __int128" or
  "unsigned int __attribute__ ((__mode__ (TI)))" types. One of these types is
  necessary to compile the MaxMind::DB::Reader::XS module.

EOF

    exit 1;
}

if (
    Config::AutoConf->compute_int(
        'MMDB_UINT128_IS_BYTE_ARRAY', undef, '#include <maxminddb_config.h>'
    )
    ) {

    warn <<'EOF';

  It looks like your installed libmaxminddb was compiled with a compiler that
  doesn't support the "unsigned __int128" type. Please recompile it with your
  current compiler, which does appear to support this type.

EOF
}

my %mb_args = (
    _mb_args(),
    c_source             => 'c',
    extra_compiler_flags => [qw(--std=c99 -Wall -g)],
    extra_linker_flags   => ['-lmaxminddb'],
);

Module::Build->new(%mb_args)->create_build_script();

sub _mb_args {
    my $data = do { local $/; <DATA> };

    if ( $data !~ /^\#/ ) {
        my $args = eval $data;
        return %{$args};
    }
    else {
        return (
            module_name          => 'MaxMind::DB::Reader::XS',
            dist_abstract        => 'Whatever',
            dist_version         => '42',
            license              => 'perl',
            recursive_test_files => 1,
        );
    }
}

__DATA__
##{ ( my $args = Data::Dumper::Dumper( $plugin->module_build_args ) ) =~ s/\$VAR\d+ =//; $args ##}
