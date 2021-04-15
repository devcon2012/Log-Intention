package Log::Intention::IntentionSummary ;

use namespace::autoclean;

use Moose ;
use MooseX::ClassAttribute ;

our $VERSION = '0.1';

use Log::Intention::IntentionStack ;
use Log::Intention::Exception ;

use Carp qw( carp longmess ) ;
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
    return -1 ;
    }

#
has 'deleted' => (
    documentation   => 'flags deleted/popped intentions',
    is              => 'rw',
    isa             => 'Bool',
    default         => ''
) ;

has 'what' => (
    documentation   => 'Intention string',
    is              => 'rw',
    isa             => 'Maybe[Str]',
    default         => ''
) ;

has '_path' => (
    documentation   => 'path on intention stack',
    is              => 'rw',
    isa             => 'Maybe[Str]',
    default         => ''
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


#

sub value_copy
    {
    my ($self) = @_ ;

    my $values = {} ;

    foreach my $v ( qw(what timestamp serial _path) )
        {
        $values -> {$v} = $self-> $v ;
        }

    return Log::Intention::IntentionSummary -> new ( $values ) ;
    }

__PACKAGE__ -> meta -> make_immutable ;

1 ;
__END__

=head1 NAME

Log::Intention::IntentionSummary - Intention base class comprising the intention data fields

Summaries are not put on the intention stack.

=head1 SYNOPSIS

  use Log::Intention::IntentionSummary ;
  my $value_copy = $intention -> value_copy ; # create a copy of an intentions data to be used any time later.

=head1 DESCRIPTION


=head2 EXPORT

None by default.



=head1 SEE ALSO

=head1 AUTHOR

Klaus Ramstöck, E<lt>klaus@ramstoeck.nameE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by Klaus Ramstöck

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
