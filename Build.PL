use strict;
use warnings;

use Module::Build;

warn <<'EOF';

  ********************************* WARNING **********************************

  This module uses Dist::Zilla for development. This Build.PL will let you run
  the tests, but you are encouraged to install Dist::Zilla and the needed
  plugins if you intend on doing any serious hacking.

  ****************************************************************************

EOF

Module::Build->new(
    module_name          => 'MaxMind::DB::Reader::File::XS',
    dist_abstract        => 'Whatever',
    dist_version         => 42,
    license              => 'perl',
    recursive_test_files => 1,
    extra_compiler_flags => [qw(-Wall -Wdeclaration-after-statement)],
    extra_linker_flags   => ['-lmaxminddb'],
)->create_build_script();
