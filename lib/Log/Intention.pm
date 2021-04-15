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

our $VERSION = '1.0';

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

  my $i = Log::Intention -> new  ( "Load config" ) ;
  if ( my $cfg = read_json ($fn) )
    {
    $i -> Log ( 'found config' ) ;
    }
  else
    {
    $i -> Throw ( "no json in $fn" ) ;
    }

=head1 DESCRIPTION

Intention logging tries to help you organize your log output so it is easier to interpret for a number of audiences.
To do so, it tries to help you make use of modern logging facilities like journald without requiring that.

Log::Intention does not work (well) with Coro, because it assumes Intentions can be represented by a stack in a LIFO order.


=head2 CONCEPTS

Log::Intention log events create 'records'. Records consist of the plain message + meta information (pid, level, timestamp...).
A structured logging target (A database, journald, ...) will recieve this data as one entry.
A streaming log target (plain file, socket ...) will receive the message 'decorated' with (parts of) the meta information in ways
you can specify.


=head2 EXPORT

(This is a Moose and thus has antlers...)

=head1 SEE ALSO

=head1 AUTHOR

Klaus Ramstöck, E<lt>klaus@ramstoeck.nameE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by Klaus Ramstöck

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
