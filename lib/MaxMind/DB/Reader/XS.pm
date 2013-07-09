package MaxMind::DB::Reader::XS;

use strict;
use warnings;
use namespace::autoclean;

use Math::Int128 qw( uint128 );
use NetAddr::IP::Util qw( bin2bcd );
use MaxMind::DB::Metadata;

use Moose;

with 'MaxMind::DB::Reader::Role::Reader';

use XSLoader;

XSLoader::load(
    __PACKAGE__,
    exists $MaxMind::DB::Reader::XS::{VERSION}
        && ${ $MaxMind::DB::Reader::XS::{VERSION} }
    ? ${ $MaxMind::DB::Reader::XS::{VERSION} }
    : 42
);

has file => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has _mmdb => (
    is        => 'ro',
    isa       => 'Str',
    init_arg  => undef,
    lazy      => 1,
    builder   => '_build_mmdb',
    predicate => '_has_mmdb',
);

# XXX - making this private & hard coding this as 2 is obviously wrong -
# eventually we need to expose the flag constants in Perl
has _flags => (
    is       => 'ro',
    isa      => 'Int',
    init_arg => undef,
    default  => 2,
);

sub _build_mmdb {
    my $self = shift;

    return $self->_open_mmdb( $self->file(), $self->_flags() );
}

sub _build_metadata {
    my $self = shift;

    my $raw = $self->_raw_metadata( $self->_mmdb() );

    return MaxMind::DB::Metadata->new($raw);
}

sub data_for_address {
    my $self = shift;
    my $addr = shift;

    return scalar $self->_data_for_address( $self->_mmdb(), $addr );
}

sub DEMOLISH {
    my $self = shift;

    $self->_close_mmdb( $self->_mmdb() )
        if $self->_has_mmdb();

    return;
}

sub _decode_bigint {
    my $buffer = shift;

    return uint128( bin2bcd( _zero_pad_left( $buffer, 16 ) ) );
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
