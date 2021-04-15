package Log::Intention::IntentionStack ;

use namespace::autoclean ;

use Moose ;
use MooseX::ClassAttribute ;

use Log::Intention::IntentionSummary ;
use Log::Intention::LogTarget::Stream ;

use Carp qw( carp longmess ) ;
our @CARP_NOT ;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Members
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

class_has '_stack' => (
    documentation => 'Intention id stack',
    is            => 'rw',
    isa           => 'ArrayRef[Int]',
    traits        => ['Array'],
    default       => sub { [] },
    handles => { all_intentions   => 'elements',
                 add_intention    => 'push',
                 get_intention    => 'get',
                 count_intentions => 'count',
                 has_intention    => 'count',
                 clear_intentions => 'clear',
                 pop_intention    => 'pop',
        },
        ) ;

class_has '_value_copies' => (
    documentation => 'Map intention ids to value copies',
    is            => 'rw',
    isa           => 'HashRef[Log::Intention::IntentionSummary]',
    traits        => ['Hash'],
    default       => sub { {} },
    handles => { set_summary      => 'set',
                 get_summary      => 'get',
                 delete_summary   => 'delete',
                 delete_summaries => 'clear'
        },
        ) ;

#
class_has '_queue' => (
    documentation => 'queue pop operations while in frozen state',
    is            => 'rw',
    isa           => 'ArrayRef[Int]',
    traits        => ['Array'],
    default       => sub { [] },
    handles => { queue         => 'elements',
                 queue_push    => 'push',
                 queue_element => 'get',
                 queue_size    => 'count',
                 clear_queue   => 'clear',
        },
        ) ;

class_has '_frozen' => (documentation => 'Intention stack frozen state flag',
                        is            => 'rw',
                        isa           => 'Bool',
                        default       => sub { ''  },
                        ) ;

class_has '_frozen_stack' => (documentation => 'longmess at freeze location',
                              is            => 'rw',
                              isa           => 'Str',
                              builder       => '_build_frozen_stack',
                              ) ;

sub _build_frozen_stack
    {
    @CARP_NOT = qw( Log::Intention::Exception ) ;
    return ;
    }

class_has '_corrupted' => (documentation => 'Intention stack corrupted flag (popped non-top element)',
                           is            => 'rw',
                           isa           => 'Bool',
                           default       => sub { ''  },
                           ) ;

class_has '_zombie' => (documentation => 'Intention serials below this value are ignored',
                        is            => 'rw',
                        isa           => 'Int',
                        default       => sub { -1  },
                        ) ;

class_has '_latest' => (documentation => 'highest intention serial so far',
                        is            => 'rw',
                        isa           => 'Int',
                        default       => sub { -1  },
                        ) ;

class_has 'LogTarget' => (documentation => 'log target object',
                          is            => 'rw',
                          isa           => 'Object',
                          lazy          => 1,
                          builder       => '_build_log_target',
                          ) ;

sub _build_log_target
    {
    return Log::Intention::LogTarget::Stream -> new ;
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Methods
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# -----------------------------------------------------------------------------
# _topintention - return top intention
#
sub _topintention
    {

    my $id = __PACKAGE__ -> _stack -> [-1] ;
    if ( $id )
        {
        return __PACKAGE__ -> _value_copies -> { $id } ;
        }
    return ;
    }

# -----------------------------------------------------------------------------
# Logger - operate the logger
#
# in    [$msg]          defaults to $intention -> what
#       [$level]        log level
#       [<intention>]   either intention or msg is required
#
sub Logger
    {
    my ($class, $msg, $level, $intention) = @_ ;

    if (1 == scalar @_)
        {
        $msg = $class ;
        undef $class ;
        }

    if (! ($msg || $intention) )
        {
        carp "neither msg nor intention to log" ;
        }

    $level      //= 'I' ;
    $intention  //= _topintention() ;
    my $target = Log::Intention::IntentionStack -> LogTarget ;
    $target -> Log ($msg, $level, $intention) ;

    return ;
    } ## end sub Logger

# -----------------------------------------------------------------------------
# path - return top intention path
#
sub path
    {
    my ($class) = @_ ;

    my $p = '' ;
    foreach my $i ($class -> all_intentions)
        {
        $p = "$p$i," ;
        }
    chop $p ;
    return $p ;
    }

# -----------------------------------------------------------------------------
# freeze - queue intention removes, dont perform them
#
sub freeze
    {
    my ($class) = @_ ;
    $class -> _frozen (1) ;
    $class -> _frozen_stack (longmess) ;
    return ;
    }

# -----------------------------------------------------------------------------
# thaw - perform queued intention removes
#
sub thaw
    {
    my ($self) = @_ ;

    $self -> _frozen (0) ;
    for (my $i = 0 ; $i < $self -> queue_size ; $i++)
        {
        my $id      = $self    -> queue_element ($i) ;
        my $head    = $self    -> get_intention (-1) ;
        my $summary = $self    -> get_summary ($head) ;
        my $text    = $summary -> what ;

        if (!$self -> remove_id ($id))
            {
            $self -> Logger ("Intention stack thaw: $id did not match $head ($text) on top", 'W' ) ;
            }
        else
            {
            $self -> Logger ( "thaw removed intention $id ($text) from stack", 'D' ) ;
            }
        }
    $self -> clear_queue ;

    $self -> _frozen_stack ('') ;

    return ;
    } ## end sub thaw


# -----------------------------------------------------------------------------
# is_corrupted - precdicate to determine if reset_intention_stack is needed
#
#
sub is_corrupted
    {
    my ($self) = @_ ;
    return $self -> _corrupted ;
    }

# -----------------------------------------------------------------------------
# reset_intention_stack - cleanup after corruption
#
#
sub reset_intention_stack
    {
    my ($self) = @_ ;
    $self -> delete_summaries ;
    $self -> clear_intentions ;
    $self -> clear_queue ;
    $self -> _corrupted (0) ;
    $self -> _frozen (0) ;
    $self -> _zombie ($self -> _latest) ;
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

    my $id   = $intention -> serial ;
    my $text = $intention -> what ;

    if ($self -> _latest >= $id)
        {
        $self -> Logger ("Tried to add zombie $id:$text", 'W ') ;
        }
    $self -> _latest ($id) ;

    if ($self -> _frozen)
        {
        $self -> Logger ("Tried to add $id:$text in frozen state", 'D' ) ;
        }
    else
        {
        $self      -> add_intention ($id) ;
        $intention -> _path ($self -> path) ;
        my $summary = $intention -> value_copy ;
        $self -> set_summary ($id, $summary) ;
        $self -> Logger ( undef, undef, $intention) ;
        }
    return ;
    } ## end sub add

# -----------------------------------------------------------------------------
# remove - pop intention stack
#
# in    $intention
#
sub remove
    {
    my ($self, $intention) = @_ ;

    my $id   = $intention -> serial ;
    my $text = $intention -> what ;

    return
        if ($self -> _zombie >= $id) ;    # ignore zombies

    if ($self -> _frozen)
        {
        $self -> queue_push ($id) ;
        }
    else
        {
        if (!$self -> remove_id ($id))
            {
            Logger ("Intention stack remove: $id ($text) was not on top") ;
            }
        $intention -> deleted ( 1 ) ;
        $self -> Logger ( undef, undef, $intention) ;
        }
    return ;
    } ## end sub remove

# -----------------------------------------------------------------------------
# remove_id - pop id from intention stack
#
# in    $id - intention id to be popped, must be on top if given
#
# ret   1       ok, top element popped
#       ""      fail, tried to pop non-top element (marks stack corrupted)
#       undef   fail, tried to pop without elements
#
sub remove_id
    {
    my ($self, $id) = @_ ;

    my $id2 ;
    if ($self -> count_intentions > 0)
        {
        $id2 = $self -> get_intention (-1) ;
        $self -> pop_intention () ;
        $self -> delete_summary ($id) ;
        }
    else
        {
        $self -> _corrupted (1) ;
        return ;
        }

    $self -> _corrupted (1)
        if ($id != $id2) ;

    return ($id == $id2) ;
    } ## end sub remove_id

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

    Logger ($class, $msg, 'E', undef, "\%L: %M\n")
        if ($msg) ;

    my $queue_size = $class -> queue_size ;

    my @stack ;
    for (my $i = $class -> count_intentions - 1 ; $i >= 0 ; $i--)
        {
        my $summary = $class -> get_summary ($class -> get_intention ($i)) ;
        my $line    = "$i: " . $summary -> what . " (" . localtime ($summary -> timestamp) . ")." ;
        $line .= "<< (CATCHED HERE)" if ($queue_size-- == 0) ;
        Logger ($class, $line, 'E') ;
        push @stack, $line ;
        }

    my $trace = $class -> _frozen_stack ;

    $class -> thaw ;

    return (\@stack, $trace)
        if (wantarray) ;

    return \@stack ;
    } ## end sub unwind

__PACKAGE__ -> meta -> make_immutable ;

1 ;
