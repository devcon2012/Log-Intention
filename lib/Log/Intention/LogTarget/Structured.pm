package Log::Intention::LogTarget::Structured ;

use namespace::autoclean ;

use Moose ;
extends 'Log::Intention::LogTarget' ;

use Carp ;
use English ;
use Storable qw(dclone) ;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Methods
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# -----------------------------------------------------------------------------
# build_record - combine structured log info
#
# in    [$msg]            message to log, defaults to $intention -> what
#       [$level]          optional level
#       [<intention>]     optional intention context object, required if $msg undefined
#
# ret   %record
#
sub build_record
    {
    my ($self, $msg, $level, $intention) = @_ ;

    my $record = $self -> get_meta ( $level, $intention ) ;
    if ( ! $msg )
        {
        $record -> {message} = $intention -> deleted ?
                  "End   " . $intention -> what :
                  "Start " . $intention -> what ;
        }
    else
        {
        $record -> {message} = $msg ;
        }
    return $record ;
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

    my $record = $self -> build_record ( $msg, $level, $intention ) ;

    print STDERR Dumper ($record) ;
    return ;
    }

__PACKAGE__ -> meta -> make_immutable ;

1 ;

__END__

=head1 NAME

Log::Intention::LogTarget::Structured  - structured log target base

=head1 SYNOPSIS

  use Log::Intention::LogTarget::Structured ;

=head1 DESCRIPTION

Base for logging to structured targets like journald. Structured log target combine
message and meta-information into one record logged.

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
