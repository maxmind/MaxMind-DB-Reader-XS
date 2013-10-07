use strict;
use warnings;

use lib 'inc';

use Config::AutoConf;
use Module::Build;

unless ( Config::AutoConf->check_type('unsigned __int128') ) {
    warn <<'EOF';

  It looks like your compiler doesn't support the "unsigned __int128"
  type. This type is necessary to compile the MaxMind::DB::Reader::XS module.

EOF

    exit 1;
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
