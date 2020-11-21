package Log::Intention::Exception ;

use namespace::autoclean;

use Moose ;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Members
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

has 'message' => (
    is              => 'ro',
    isa             => 'Str',
    ) ;

has 'stack' => (
    is              => 'ro',
    isa             => 'Str',
    default         => ''
    ) ;

__PACKAGE__ -> meta -> make_immutable ;

1;