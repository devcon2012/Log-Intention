package Log::Intention::LogTarget ;

use namespace::autoclean ;
use English ;

use Moose ;

use Carp ;
use Storable qw(dclone) ;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Methods
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

has 'global_meta' => (
    documentation => 'log message global meta info (PID eg)',
    is            => 'rw',
    isa           => 'HashRef[Str]',
    traits        => ['Hash'],
    builder       => '_build_global_meta',
    handles => { set_meta_value  => 'set',
                 get_meta_value  => 'get',
                 delete_meta_key => 'delete',
                 has_meta_key    => 'exists',
                 get_meta_keys   => 'keys',
                 get_meta_values => 'values',
                 get_meta_pairs  => 'kv',
        },
        ) ;

sub _build_global_meta
    {
    my $meta = { pid => $PID,
                 } ;

    return $meta ;
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Methods
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# -----------------------------------------------------------------------------
# get_meta - combine global meta info and intention specific info
#
# in    [$level]          log level
#       [<intention>]     optional intention context object, required if $msg undefined
#
# ret   %meta
#
sub get_meta
    {
    my ($self, $level, $intention) = @_ ;

    my $meta = dclone ($self -> global_meta) ;

    $meta -> {timestamp}   = time ;
    $meta -> {timestr}= localtime ;
    $meta -> {level}  = $level if (defined $level) ;
    if ( ref $intention )
        {
        $meta -> {path}   = $intention -> _path ;
        $meta -> {serial} = $intention -> serial ;
        $meta -> {itimestamp}  = $intention -> timestamp ;
        }
    return $meta ;
    }

# -----------------------------------------------------------------------------
# Log - write a msg to a target
#
# in    [$msg]            message to log, defaults to $intention -> what
#       [$level]          optional level
#       [<intention>]     optional intention context object, required if $msg undefined

sub Log
    {
    my ($self, $msg, $level, $intention) = @_ ;

    carp "pure virtual method not overloaded" ;
    return ;
    }

__PACKAGE__ -> meta -> make_immutable ;

1 ;
__END__

=head1 NAME

Log::Intention::LogTarget - Virtual base for all Intention logging targets

=head1 SYNOPSIS

  use Log::Intention::LogTarget::Stream ;       # log to a stream
  use Log::Intention::LogTarget::JournalD ;     # log to journald
  ...

=head1 DESCRIPTION

A logtarget defines meta-info, which will be combined with log messages.
Unstructured log targets like streams decorate messages with meta info, Structured
log targets form a record combining meta info and message which is then written.

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
