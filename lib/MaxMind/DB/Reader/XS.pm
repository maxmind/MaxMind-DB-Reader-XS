package MaxMind::DB::Reader::XS;

use strict;
use warnings;
use namespace::autoclean;

use 5.010000;

use Math::Int128 qw( uint128 );
use MaxMind::DB::Metadata;
use MaxMind::DB::Reader 0.050000;
use MaxMind::DB::Types qw( Str Int );

use Moo;

with 'MaxMind::DB::Reader::Role::Reader',
    'MaxMind::DB::Reader::Role::HasMetadata';

use XSLoader;

XSLoader::load(
    __PACKAGE__,
    exists $MaxMind::DB::Reader::XS::{VERSION}
        && ${ $MaxMind::DB::Reader::XS::{VERSION} }
    ? ${ $MaxMind::DB::Reader::XS::{VERSION} }
    : '42'
);

has file => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has _mmdb => (
    is        => 'ro',
    init_arg  => undef,
    lazy      => 1,
    builder   => '_build_mmdb',
    predicate => '_has_mmdb',
);

# XXX - making this private & hard coding this is obviously wrong - eventually
# we need to expose the flag constants in Perl
has _flags => (
    is       => 'ro',
    isa      => Int,
    init_arg => undef,
    default  => 0,
);

sub BUILD { $_[0]->_mmdb }

sub _data_for_address {
    my $self = shift;

    return $self->__data_for_address( $self->_mmdb(), @_ );
}

sub _read_node {
    my $self = shift;

    return $self->__read_node( $self->_mmdb(), @_ );
}

sub _get_entry_data {
    my $self = shift;

    return $self->__get_entry_data( $self->_mmdb(), @_ );
}

sub _build_mmdb {
    my $self = shift;

    return $self->_open_mmdb( $self->file(), $self->_flags() );
}

sub _build_metadata {
    my $self = shift;

    my $raw = $self->_raw_metadata( $self->_mmdb() );

    return MaxMind::DB::Metadata->new($raw);
}

sub DEMOLISH {
    my $self = shift;

    $self->_close_mmdb( $self->_mmdb() )
        if $self->_has_mmdb();

    return;
}

sub _decode_bigint {
    my $buffer = shift;

    my $int = uint128(0);

    my @unpacked = unpack( 'NNNN', _zero_pad_left( $buffer, 16 ) );
    for my $piece (@unpacked) {
        $int = ( $int << 32 ) | $piece;
    }

    return $int;
}

# Copied from MaxMind::DB::Reader::Decoder
sub _zero_pad_left {
    my $content        = shift;
    my $desired_length = shift;

    return ( "\x00" x ( $desired_length - length($content) ) ) . $content;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Fast XS implementation of MaxMind DB reader
