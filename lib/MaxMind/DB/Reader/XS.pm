package MaxMind::DB::Reader::XS;

use 5.012000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use MaxMind::DB::Reader::XS ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [
        qw(

            )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load( 'MaxMind::DB::Reader::XS', $VERSION );

sub record_for_hostname {
    my ( $self, $host ) = @_;
    return scalar( $self->lookup_by_host($host) );
}

sub record_for_address {
    my ( $self, $addr ) = @_;
    return scalar( $self->lookup_by_ip($addr) );
}

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
