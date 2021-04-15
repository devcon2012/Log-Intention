package Log::Intention::LogTarget::Stream ;

use namespace::autoclean;

use Moose ;
extends 'Log::Intention::LogTarget' ;

use Carp ;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Members
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

has 'decoration' => (
    documentation   => 'log message decoration',
    is              => 'rw',
    isa             => 'Str',
    lazy            => 1,
    builder         => '_build_log_decoration' ,
) ;
sub _build_log_decoration
    {
    return "\%timestr \%level : \%M\n" ;
    }

has 'start_decoration' => (
    documentation   => 'log message decoration on intention push',
    is              => 'rw',
    isa             => 'Str',
    lazy            => 1,
    default         => "\%timestr > : Start \%M (%path)\n" ,
) ;

has 'end_decoration' => (
    documentation   => 'log message decoration on intention pop',
    is              => 'rw',
    isa             => 'Str',
    lazy            => 1,
    default         => "\%timestr < : End \%M (%path)\n" ,
) ;

has 'logstream' => (
    documentation   => 'handle to log to',
    is              => 'rw',
    isa             => 'Any',
    lazy            => 1,
    builder         => '_build_logstream'
    ) ;
sub _build_logstream
    {
    return *STDERR ;
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Methods
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub BUILD
    {
    my ($self) = @_ ;

    # set default decoration style ...
    return ;
    }

# -----------------------------------------------------------------------------
# decorate - decorate a message
#       place PID/Timestamp/... info in message
#
#
# in    $msg            log message, will end in $class -> handle
#       %meta
#       $decoration
#
# ret   $decorated      decorated message
#
sub decorate
    {
    my ($self, $msg, $meta, $decoration ) = @_ ;

    $decoration //= '%M' ;

    my $out = $decoration ;
    foreach my $k ( sort keys %$meta )
        {
        my $v = $meta -> {$k} ;
        $out =~ s/\%$k/$v/ ;
        }
    $out =~ s/\%M/$msg/ ;
    return $out ;
    }

# -----------------------------------------------------------------------------
#
# _decorated_msg - replace PID/Timestamp/... info in message
#
# %M Message
# %T Timestamp
# %P PID
# %I intention Id
# %L message level
# %A message path
#
# in    $msg            log message, will end in $class -> handle
#       [$intention]    context of this message

sub _decorated_msg
    {
    my ($class, $msg, $lvl, $intention, $deco) = @_  ;

    $deco  //= $class -> decoration ;
    my $ts   = localtime ;
    my $pid  = $$ ;
    my $path = '' ;
    $path    = $intention -> _path
        if ( ref $intention && $intention -> can ( '_path' ) ) ;
    my $id   = $intention ||  '' ;
    $id      = $intention -> serial
        if ( ref $intention && $intention -> can ( 'serial' ) ) ;

    $deco    =~ s/\%A/$path/ ;
    $deco    =~ s/\%T/$ts/ ;
    $deco    =~ s/\%P/$pid/ ;
    $deco    =~ s/\%I/$id/ ;
    $deco    =~ s/\%L/$lvl/ ;
    $deco    =~ s/\%M/$msg/ ; # last - might contain %X...

    return $deco;
    }
   #  my $out = Log::Intention::IntentionStack -> _decorated_msg ( $msg, $level, $intention, $decoration ) ;


sub get_decoration
    {
    my ($self, $msg, $intention ) = @_ ;

    my $decoration = $self -> decoration ;

    if ( ! $msg )
        {
        $msg = $intention -> what ;
        $decoration = $intention -> deleted ?
                $self -> end_decoration :
                $self -> start_decoration ;
        }

    return ($msg, $decoration ) ;
    }

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

    print { $self -> logstream } "$out" ;
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
