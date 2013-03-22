package MaxMind::DB::Reader::XS;

use 5.012000;
use strict;
use warnings;

use Moose;

extends 'MaxMind::DB::Reader';

our $VERSION = '0.03';

require XSLoader;
XSLoader::load( 'MaxMind::DB::Reader::XS', $VERSION );

use Params::Validate;
use NetAddr::IP::Util 'bin2bcd';

our @_simple_metadata_keys = (
    'ip_version',
    'binary_format_minor_version',
    'description',
    'node_count',
    'database_type',
    'languages',
    'record_size',
    'binary_format_major_version'
);

our @_special_metadata_keys = (
    'build_epoch',
);

our @_metadata_keys = ( @_simple_metadata_keys, @_special_metadata_keys );

for my $method (@_simple_metadata_keys) {
    no strict 'refs';
    *$method = sub { $_[0]->metadata->{$method} };
}

sub build_epoch { bin2bcd( pack x8a8 => $_[0]->metadata->{build_epoch} ) }

sub metadata_to_encode {
    my $self     = shift;
    my $metadata = $self->metadata;
    $metadata->{build_epoch}
        = bin2bcd( pack x8a8 => $metadata->{build_epoch} );
    return $metadata;
}

sub new {
    my $class  = shift;
    my %params = validate( @_, { file => 1 } );
    my $self   = $class->open( $params{file}, 2 ) or die;
    return $self;
}

sub _reader {
    return $_[0];
}

sub data_for_address {
    my ( $self, $addr ) = @_;
    return scalar( $self->lookup_by_ip($addr) );
}

=pod

sub record_for_hostname {
    my ( $self, $host ) = @_;
    return scalar( $self->lookup_by_host($host) );
}

sub record_for_address {
    my ( $self, $addr ) = @_;
    return scalar( $self->lookup_by_ip($addr) );
}

=cut

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

MaxMind::DB::Reader::XS - Perl extension for blah blah blah

=head1 SYNOPSIS

  use MaxMind::DB::Reader::XS;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for MaxMind::DB::Reader::XS, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

bz, E<lt>bz@localE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by bz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
