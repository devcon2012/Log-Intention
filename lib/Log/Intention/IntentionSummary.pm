package Log::Intention::IntentionSummary ;

use namespace::autoclean;
use Moose ;

#
has 'serial' => (
    documentation   => 'Intention serial number',
    is              => 'rw',
    isa             => 'Int',
) ;

has 'timestamp' => (
    documentation   => 'Intention timestamp',
    is              => 'rw',
    isa             => 'Int',
    builder         => '_build_timestamp'
) ;
sub _build_timestamp
    {
    return time ;
    }

has 'what' => (
    documentation   => 'Intention string',
    is              => 'rw',
    isa             => 'Maybe[Str]',
    default         => ''
) ;

#

sub extract
    {
    my $intention = shift ;
    return Log::Intention::IntentionSummary -> new
            (
            what => $intention -> what,
            serial => $intention -> serial
            ) ;
    }

__PACKAGE__ -> meta -> make_immutable ;

1 ;
