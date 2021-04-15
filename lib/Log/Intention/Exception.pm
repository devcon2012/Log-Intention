package Log::Intention::Exception ;

use namespace::autoclean;

use Moose ;

use overload '""' => 'stringify' ;

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

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Methods
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Note: Do not use ref on self in stringify, because this would cause deep recursion ...
sub stringify
    {
    my ( $self ) = @_ ;

    my $m = $self -> message || '(No message)';
    my $s = $self -> stack ? $self -> stack . "\n" : '' ;

    my $str = "Log::Intention::Exception: $m\n$s" ;
    return $str ;
    }

__PACKAGE__ -> meta -> make_immutable ;

1;