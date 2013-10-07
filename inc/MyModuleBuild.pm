package inc::MyModuleBuild;

use strict;
use warnings;
use namespace::autoclean;

use Moose;

extends 'Dist::Zilla::Plugin::ModuleBuild';

around module_build_args => sub {
    my $orig = shift;
    my $self = shift;

    my $args = $self->$orig(@_);

    $args->{c_source}             = 'c';
    $args->{extra_compiler_flags} = ['-std=c99'];
    $args->{extra_linker_flags}   = ['-lmaxminddb'];

    return $args;
};

__PACKAGE__->meta()->make_immutable();

1;
