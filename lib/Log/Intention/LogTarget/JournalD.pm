package Log::Intention::LogTarget::JournalD ;

use namespace::autoclean;

use Moose ;
extends 'Log::Intention::LogTarget::Structured' ;

use Log::CJournalD ':all' ;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Methods
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# -----------------------------------------------------------------------------
# map_meta_to_journald -
#
# in    %meta
#
# ret   %jrecord
#
sub map_meta_to_journald
    {
    my ($self, $record) = @_ ;

    my $jrecord = $record ;

    return $jrecord ;
    }

# -----------------------------------------------------------------------------
# Log - write a msg to a target
#
# in    $msg            plain message
#       $level
#       <intention>     intention context object

sub Log
    {
    my ($self, $msg, $level, $intention ) = @_ ;

    my $record = $self -> build_record ( $msg, $level, $intention ) ;

    my $jrecord = $self -> map_meta_to_journald ( $record ) ;
    sd_journal_sendv ( $jrecord ) ;
    return ;
    }

__PACKAGE__ -> meta -> make_immutable ;

1;