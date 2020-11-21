package Log::Intention::IntentionStack ;

use namespace::autoclean;

use Moose ;
use MooseX::ClassAttribute ;

use  Log::Intention::IntentionSummary ;

use Carp qw( longmess ) ;
our @CARP_NOT;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Members
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

class_has '_stack' => (
    documentation   => 'Intention id stack',
    is              => 'rw',
    isa             => 'ArrayRef[Int]',
    traits          => ['Array'],
    default         => sub {[]},
    handles => {
        all_intentions      => 'elements',
        add_intention       => 'push',
        get_intention       => 'get',
        count_intentions    => 'count',
        has_intention       => 'count',
        clear_intentions    => 'clear',
        pop_intention       => 'pop',
    },
) ;

class_has '_map' => (
    documentation   => 'Map intention ids to summaries',
    is              => 'rw',
    isa             => 'HashRef[Log::Intention::IntentionSummary]',
    traits          => ['Hash'],
    default         => sub { {} },
    handles         => {
        set_summary       => 'set',
        get_summary       => 'get',
        delete_summary    => 'delete',
        delete_summaries  => 'clear'
        },
    ) ;

#
class_has '_queue' => (
    documentation   => 'queue pop operations while in frozen state',
    is              => 'rw',
    isa             => 'ArrayRef[Int]',
    traits          => ['Array'],
    default         => sub {[]},
    handles => {
        queue         => 'elements',
        queue_push    => 'push',
        queue_element => 'get' ,
        queue_size    => 'count',
        clear_queue   => 'clear',
    },
) ;

class_has '_frozen' => (
    documentation   => 'Intention stack frozen state flag',
    is              => 'rw',
    isa             => 'Int',
    default         => sub { 0 },
    ) ;

class_has '_frozen_stack' => (
    documentation   => 'longmess at freeze location',
    is              => 'rw',
    isa             => 'Str',
    builder         => '_build_frozen_stack',
    ) ;
sub _build_frozen_stack
    {
    @CARP_NOT = qw( Log::Intention::Exception ) ;
    return ;
    }

class_has '_corrupted' => (
    documentation   => 'Intention stack corrupted flag (popped non-top element)',
    is              => 'rw',
    isa             => 'Int',
    default         => sub { 0 },
    ) ;

class_has '_zombie' => (
    documentation   => 'Intention serials below this value are ignored',
    is              => 'rw',
    isa             => 'Int',
    default         => sub { -1 },
    ) ;

class_has '_latest' => (
    documentation   => 'highest intention serial so far',
    is              => 'rw',
    isa             => 'Int',
    default         => sub { -1 },
    ) ;

class_has 'LogTarget' => (
    documentation   => 'log target- handle, coderef, ..',
    is              => 'rw',
    isa             => 'Any',
    lazy            => 1,
    default         => sub { *STDERR },
    ) ;

class_has 'decoration' => (
    documentation   => 'log message decoration',
    is              => 'rw',
    isa             => 'Str',
    lazy            => 1,
    builder         => '_build_log_decoration' ,
) ;
sub _build_log_decoration
    {
    return "\%L: \%M\n" ;
    }


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Methods
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# -----------------------------------------------------------------------------
#
# _decorated_msg -
#
# %M Message
# %T Timestamp
# %P PID
# %I intention Id
# %L message level
#
# in    $msg            log message, will end in $class -> handle
#       [$intention]    context of this message

sub _decorated_msg
    {
    my ($class, $msg, $lvl, $intention) = @_  ;

    my $deco =  Log::Intention::IntentionStack -> decoration ;

    my $ts   = localtime ;
    my $pid  = $$ ;
    my $id   = $intention ||  '' ;
    $id      = $intention -> serial
        if ( ref $intention && $intention -> can ( 'serial' ) ) ;

    $deco    =~ s/\%T/$ts/ ;
    $deco    =~ s/\%P/$pid/ ;
    $deco    =~ s/\%I/$id/ ;
    $deco    =~ s/\%L/$lvl/ ;
    $deco    =~ s/\%M/$msg/ ; # last - might contain %X...

    return $deco;
    }

sub Logger
    {
    my ( $class, $msg, $level, $intention )  = @_ ;

    if ( 1 == scalar @_ )
        {
        ( $msg ) = @_ ;
        }
    else
        {
        ( $class, $msg, $level )  = @_ ;
        }

    $level //= 'I' ;

    my $out = Log::Intention::IntentionStack -> _decorated_msg ( $msg, $level, $intention ) ;

    print {  Log::Intention::IntentionStack -> LogTarget } $out ;
    return ;
    }

# -----------------------------------------------------------------------------
# freeze - queue intention removes, dont perform them
#
sub freeze
    {
    my ($class) = @_ ;
    $class -> _frozen(1) ;
    $class -> _frozen_stack ( longmess ) ;
    return ;
    }

# -----------------------------------------------------------------------------
# thaw - perform queued intention removes
#
sub thaw
    {
    my ($self) = @_ ;

    $self -> _frozen(0) ;
    for ( my $i=0; $i < $self -> queue_size; $i++ )
        {
        my $id      = $self -> queue_element($i) ;
        my $head    = $self -> get_intention(-1) ;
        my $summary = $self -> get_summary($head) ;
        my $text    = $summary -> what ;
        if ( ! $self -> remove_id($id) )
            {
            Logger ("Intention stack thaw: $id did not match $head ($text) on top" );
            }
        }
    $self -> clear_queue ;

    $self -> _frozen_stack ( '' ) ;

    return ;
    }

# -----------------------------------------------------------------------------
# summary - create new intention summary
#
# in    $intention
#
# ret   $summary
#
sub summary
    {
    my ($self, $intention) = @_ ;
    return Log::Intention::IntentionSummary::extract($intention) ;
    }

# -----------------------------------------------------------------------------
# is_corrupted - precdicate to determine if reset_intention_stack is needed
#
#
sub is_corrupted
    {
    my ( $self ) = @_ ;
    return $self -> _corrupted  ;
    }

# -----------------------------------------------------------------------------
# reset_intention_stack - cleanup after corruption
#
#
sub reset_intention_stack
    {
    my ( $self ) = @_ ;
    $self -> delete_summaries ;
    $self -> clear_intentions ;
    $self -> clear_queue ;
    $self -> _corrupted (0) ;
    $self -> _frozen (0) ;
    $self -> _zombie ( $self -> _latest ) ;
    return ;
    }

# -----------------------------------------------------------------------------
# add - push intention on stack top
#
# in    $intention
#
sub add
    {
    my ($self, $intention) = @_ ;

    my $id = $intention -> serial ;
    my $text = $intention -> what ;

    if ( $self -> _latest >= $id )
        {
        Logger ( "Tried to add zombie $id:$text" ) ;
        }
    $self -> _latest ( $id ) ;

    if ( $self -> _frozen )
        {
        Logger ( "Tried to add $id:$text in frozen state" ) ;
        }
    else
        {
        my $summary =  $self -> summary ($intention) ;
        my $msg = $self -> format_summary ( "Start", $summary ) ;
        Logger ( $msg ) ;
        $self -> add_intention ($id) ;
        $self -> set_summary ( $id, $summary ) ;
        }
    return ;
    }

# -----------------------------------------------------------------------------
# format_summary - format intention summary for use in unwind()
#
# in    $prefix
#       $intention_summary
#
# ret   $string
#
sub format_summary
    {
    my ($self, $prefix, $summary) = @_ ;

    #my $id = sprintf("%04d", $summary -> serial) ;
    my $id = sprintf("%02d", $self -> count_intentions ) ;
    my $text = $summary -> what ;
    my $t = $summary -> timestamp ;

    my $depth = $self -> count_intentions + 1 ;

    my $line = ('>' x $depth) . (' ' x (6-$depth) ). "$prefix (" . localtime($t) . ") $id- $text"; #   ($prefix)" ;
    return $line ;
    }

# -----------------------------------------------------------------------------
# remove - pop intention stack
#
# in    $intention
#
sub remove
    {
    my ($self, $intention) = @_ ;

    my $id = $intention -> serial ;
    my $text = $intention -> what ;

    return
        if ( $self -> _zombie >= $id ) ; # ignore zombies

    if ( $self -> _frozen )
        {
        $self -> queue_push ( $id ) ;
        }
    else
        {
        my $summary =  $self -> summary ($intention) ;
        if ( ! $self -> remove_id($id) )
            {
            Logger( "Intention stack remove: $id ($text) was not on top" );
            }
        my $msg = $self -> format_summary ( "End  ", $summary ) ;
        Logger ( $msg ) ;
        }
    return ;
    }

# -----------------------------------------------------------------------------
# remove_id - pop intention stack
#
# in    [$id] - intention id to be popped, must be on top if given
#
# ret   1       ok, top element popped
#       ""      fail, tried to pop non-top element (marks stack corrupted)
#       undef   fail, tried to pop without elements
#
sub remove_id
    {
    my ($self, $id) = @_ ;

    return
        if ( $self -> count_intentions == 0 ) ;

    my $id2 = $self -> get_intention( -1 ) ;
    $id //= $id2 ;

    $self -> pop_intention () ;
    $self -> delete_summary ( $id ) ;

    $self -> _corrupted(1)
        if ( ! ($id == $id2) ) ;

    return  ( $id == $id2 )  ;
    }

# -----------------------------------------------------------------------------
# unwind - dump intention stack. will thaw afterwards, used in catch {}
#
# in    $msg - msg printed before dump
#
# ret   ( @intention_stack, $longmess ) if wantarray
#        @intention_stack
#
sub unwind
    {
    my ($class, $msg) = @_ ;

    my $queue_size = $class -> queue_size ;

    my @stack ;
    for( my $i = $class -> count_intentions-1; $i>=0; $i-- )
        {
        my $summary =  $class -> get_summary ( $class -> get_intention($i) ) ;
        my $line =  "$i: " . $summary -> what ." (". localtime($summary -> timestamp) .")." ;
        $line .= "<< (CATCHED HERE)" if ( $queue_size-- == 0 ) ;
        Logger( $line ) ;
        push @stack, $line ;
        }

    my $trace = $class -> _frozen_stack ;

    $class -> thaw ;

    return (\@stack, $trace)
        if ( wantarray ) ;

    return \@stack ;
    }

__PACKAGE__ -> meta -> make_immutable ;

1;