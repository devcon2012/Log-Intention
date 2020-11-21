package Log::Intention;

# Intentions help make logs readable:
#
# At the beginning of a sub/block/... , create one like so:
#   my $i = NewIntention ( 'Demonstrate InfoGopher use' ) ;
#
# Catch Exceptions where appropriate like so:
#   catch
#       {
#       my $e = $_ ;  UnwindIntentionStack($e -> what) ;
#       }
#
# Do not die! This would remove intentions from the stack that we need
#   for analysis
#
#
use namespace::autoclean;

use Moose ;
use MooseX::ClassAttribute ;

our $VERSION = '0.01';

use Log::Intention::IntentionStack ;
use Log::Intention::Exception ;

use Carp qw( longmess ) ;
our @CARP_NOT;

#
class_has '_serial_counter' => (
    documentation   => 'Intention serial number',
    is              => 'rw',
    isa             => 'Int',
    default         => sub { 1 },
) ;

#
has 'serial' => (
    documentation   => 'Intention serial number',
    is              => 'rw',
    isa             => 'Int',
    builder         => '_get_serial'
) ;
sub _get_serial
    {
    my $self = shift ;
    my $serial = $self -> _serial_counter ;
    $self -> _serial_counter($serial + 1) ;
    return $serial ;
    }

has 'what' => (
    documentation   => 'Intention string',
    is              => 'rw',
    isa             => 'Maybe[Str]',
    default         => ''
) ;

#

sub BUILD
    {
    my ($self) = @_ ;
    Log::Intention::IntentionStack -> add ( $self ) ;
    return ;
    }

sub DEMOLISH
    {
    my ($self) = @_ ;
    Log::Intention::IntentionStack -> remove ( $self ) ;
    return ;
    }

# -----------------------------------------------------------------------------
# Throw - throw an exception in the context of an intention
#
# in    $arg - exception or message
#
sub Throw
    {
    my ($class, $arg) = @_ ;

    my ( $msg, $e ) ;

    if ( ref $arg )
        {
        $msg = $e -> message ;
        $e = $arg ;
        }
    else
        {
        $msg = $arg ;
        $e   = Log::Intention::Exception -> new ( { message => $msg, stack => longmess } )  ;
        }

    Log ( $class, $msg, 'E' ) ;

    Log::Intention::IntentionStack -> freeze ;
    die $e;
    }

# -----------------------------------------------------------------------------
# Log - Log a message in the context of an intention or as class method
#
# in    $message - message to log
#
sub LogTarget
    {
    my ($class, $target) = @_ ;

    Log::Intention::IntentionStack-> LogTarget ( $target ) ;

    return ;
    }

# -----------------------------------------------------------------------------
# Log - Log a message in the context of an intention or as class method
#
# in    $message - message to log
#
sub Log
    {
    my ($class, $message, $level) = @_ ;

    my $self = ( ref $class ? $class : undef ) ;
    Log::Intention::IntentionStack -> Logger ( $message, $level, $self ) ;

    return ;
    }

# -----------------------------------------------------------------------------
# NewIntention - Log a message in the context of an intention
#
# in    $message - message to log
#
sub NewIntention
    {
    my ($class, $message) = @_ ;

    $message = $class
      if ( 1 == scalar @_ ) ;
    my $i = Log::Intention -> new ( { what => $message } ) ;
    return $i;
    }

__PACKAGE__ -> meta -> make_immutable ;

1 ;
__END__

=head1 NAME

Log::Intention - Intention logging

=head1 SYNOPSIS

  use Log::Intention;

=head1 DESCRIPTION

Stub documentation for Log::Intention, created by h2xs. It looks like the
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

Klaus Ramstöck, E<lt>klaus@(none)E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Klaus Ramstöck

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
