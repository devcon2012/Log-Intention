package Log::Intention;

# Intentions help make logs readable:
#
# At the beginning of a sub/block/... , create one like so:
#   my $i = NewIntention ( 'Demonstrate InfoGopher use' ) ;
#
# Catch Exceptions where appropriate like so:
#
#   catch
#       {
#       my $e = $_ ;
#       UnwindIntentionStack($e -> what) ;
#       }
#
#
use namespace::autoclean;

use Moose ;
use MooseX::ClassAttribute ;

extends 'Log::Intention::IntentionSummary' ;

our $VERSION = '0.1';

use Log::Intention::IntentionStack ;
use Log::Intention::Exception ;

use Carp qw( carp longmess ) ;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Methods
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_serial
    {
    my $self = shift ;
    my $serial = $self -> _serial_counter ;
    $self -> _serial_counter($serial + 1) ;
    return $serial ;
    }

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
# LogTarget - change log target
#
# in    <target> - a Log::Intention::LogTarget ;
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

  my $i = Log::Intention::NewIntention ( "Load config" ) ;

=head1 DESCRIPTION

Create an intention which is then put on the Intention stack.

=head2 EXPORT


=head1 SEE ALSO

=head1 AUTHOR

Klaus Ramstöck, E<lt>klaus@ramstoeck.nameE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by Klaus Ramstöck

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
