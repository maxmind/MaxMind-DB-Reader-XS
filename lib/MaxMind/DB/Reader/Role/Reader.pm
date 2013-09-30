package MaxMind::DB::Reader::Role::Reader;

use strict;
use warnings;
use namespace::autoclean;

use Data::Validate::IP 0.16 qw( is_ipv4 is_ipv6 is_private_ipv4 is_private_ipv6 );
use Net::Works::Address 0.12;
use MaxMind::DB::Types qw( Metadata );

use Moo::Role;

use constant DEBUG => $ENV{MAXMIND_DB_READER_DEBUG};

has metadata => (
    is        => 'ro',
    lazy      => 1,
    isa       => Metadata,
    builder   => '_build_metadata',
);

with 'MaxMind::DB::Role::Debugs';

sub record_for_address {
    my $self = shift;
    my $addr = shift;

    die 'You must provide an IP address to look up'
        unless defined $addr and length $addr;

    die
        "The IP address you provided ($addr) is not a valid IPv4 or IPv6 address"
        unless is_ipv4($addr) || is_ipv6($addr);

    die "The IP address you provided ($addr) is not a public IP address"
        if is_private_ipv4($addr) || is_private_ipv6($addr);

    return $self->_data_for_address($addr);
}

1;
