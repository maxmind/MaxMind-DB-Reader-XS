requires "Math::Int128" => "0";
requires "MaxMind::DB::Metadata" => "0.040001";
requires "MaxMind::DB::Reader" => "1.000012";
requires "MaxMind::DB::Reader::Role::HasMetadata" => "0";
requires "MaxMind::DB::Reader::Role::Reader" => "0";
requires "MaxMind::DB::Types" => "0";
requires "Moo" => "0";
requires "XSLoader" => "0";
requires "namespace::autoclean" => "0";
requires "perl" => "5.010000";
requires "strict" => "0";
requires "warnings" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "Module::Implementation" => "0";
  requires "Net::Works::Network" => "0.21";
  requires "Path::Class" => "0.27";
  requires "Test::Fatal" => "0";
  requires "Test::MaxMind::DB::Common::Util" => "0";
  requires "Test::More" => "0.96";
  requires "Test::Number::Delta" => "0";
  requires "Test::Requires" => "0";
  requires "autodie" => "0";
  requires "lib" => "0";
  requires "perl" => "5.010000";
  requires "utf8" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "Module::Build" => "0.28";
  requires "perl" => "5.008";
};

on 'develop' => sub {
  requires "Code::TidyAll" => "0.24";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Perl::Critic" => "1.123";
  requires "Perl::Tidy" => "20140711";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::Code::TidyAll" => "0.24";
  requires "Test::EOL" => "0";
  requires "Test::LeakTrace" => "0";
  requires "Test::More" => "0.88";
  requires "Test::NoTabs" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Spelling" => "0.12";
  requires "Test::Synopsis" => "0";
  requires "Test::Version" => "1";
};
