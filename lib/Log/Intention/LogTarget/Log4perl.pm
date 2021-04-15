package Log::Intention::LogTarget::Log4perl ;

use namespace::autoclean;

use Moose ;
extends 'Log::Intention::LogTarget::Stream' ;

use Carp ;

use Log::Log4perl ;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Members
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

has 'logpackage' => (
    documentation   => 'Log4perl logging package name',
    is              => 'rw',
    isa             => 'Str',
    lazy            => 1,
    default         => ''
    ) ;

has 'logger' => (
    documentation   => 'Log4perl logger object',
    is              => 'rw',
    isa             => 'Any',
    lazy            => 1,
    builder         => '_build_logger'
    ) ;
sub _build_logger
    {
    my ($self) = @_ ;
    my $p = $self -> logpackage ;
    if ( ! $p )
        {
        Log::Log4perl -> easy_init( ) ;
        $self -> logpackage( ref $self ) ;
        }
    return Log::Log4perl -> get_logger( $p ) ;
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Methods
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# -----------------------------------------------------------------------------
# Log - write a msg to a target
#
# in    [$msg]            message to log, defaults to $intention -> what
#       [$level]          optional level
#       [<intention>]     optional intention context object, required if $msg undefined

sub Log
    {
    my ($self, $msg, $level, $intention ) = @_ ;

    my ($out, $decoration) = $self -> get_decoration ( $msg, $intention ) ;

    my $meta = $self -> get_meta ( $level, $intention ) ;
    $out = $self -> decorate ($out, $meta, $decoration) ;

    $level //= 'I' ;
    my $logger = $self -> logger ;

    if ( $level eq 'D' )
        {
        $logger -> debug ( $out ) ;
        }
    elsif ( $level eq 'W' )
        {
        $logger -> warn ( $out ) ;
        }
    elsif ( $level eq 'E' )
        {
        $logger -> error ( $out ) ;
        }
    elsif ( $level eq 'F' )
        {
        $logger -> fatal ( $out ) ;
        }
    else # level == 'I', hopefully ..
        {
        $logger -> info ( $out ) ;
        }

    return ;
    }

__PACKAGE__ -> meta -> make_immutable ;

1;

__END__

=head1 NAME

Log::Intention::LogTarget::Stream  - unstructured log target base

=head1 SYNOPSIS

  use Log::Intention::LogTarget::Stream ;

  Log::Intention::LogTarget::Stream -> configure_decoration ( $decoration ) ;

=head1 DESCRIPTION

Base for logging to unstructured  target like plain files. Will try to work around the limitations of this
approach by 'decorating' the logged messages with meta-information like timestamp, pid, ...

=head2 EXPORT


=head1 SEE ALSO

Log::Intention::LogTarget

=head1 AUTHOR

Klaus Ramstöck, E<lt>klaus@ramstoeck.nameE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by Klaus Ramstöck

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
