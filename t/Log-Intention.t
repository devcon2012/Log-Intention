# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Log-Intention.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Try::Tiny ;
use Data::Dumper ;

use Test::More tests => 16 ;
BEGIN { use_ok('Log::Intention') };

#########################

sub NewIntention
    {
    return Log::Intention::NewIntention(@_) ;
    }

my $intention = NewIntention ( 'test1' ) ;
    {
    my $i = NewIntention ( 'test2' ) ;
    ok ( ! Log::Intention::IntentionStack -> is_corrupted , 'Intention stack ok') ;
    undef $i ;
    ok ( ! Log::Intention::IntentionStack -> is_corrupted, 'undef top did not corrupt' ) ;
    }
undef $intention ;
ok ( ! Log::Intention::IntentionStack -> is_corrupted , 'undef all did not corrupt') ;

$intention = NewIntention ( 'test1b' ) ;
    {
    my $i = NewIntention ( 'test2b' ) ;
    ok ( ! Log::Intention::IntentionStack -> is_corrupted , 'Intention stack ok lvl2' ) ;
        {
        my $i = NewIntention ( 'test3b' ) ;
        ok ( ! Log::Intention::IntentionStack -> is_corrupted, 'Intention stack ok lvl3' ) ;
        }
    }
ok ( ! Log::Intention::IntentionStack -> is_corrupted, 'Intention stack ok lvl0' ) ;
    {
    my $i1 = NewIntention ( 'test3b' ) ;
    ok ( ! Log::Intention::IntentionStack -> is_corrupted, 'Intention stack ok lvl2b') ;

    my $i2 = NewIntention ( 'test4b' ) ;
    ok ( ! Log::Intention::IntentionStack -> is_corrupted, 'Intention stack ok lvl3b' ) ;
    undef ( $i1 ) ;

    ok ( Log::Intention::IntentionStack -> is_corrupted, 'force undef against stack order corrupts' ) ;
    }

undef $intention ;
Log::Intention::IntentionStack -> reset_intention_stack ;
ok ( ! Log::Intention::IntentionStack -> is_corrupted, 'Intention stack ok after reset' ) ;

$intention = NewIntention ( 'test1c' ) ;

my $stack = Log::Intention::IntentionStack -> unwind ("bla") ;
# diag( Dumper($stack) );

ok ( 1 == scalar @$stack, 'Intention stack count ok' ) ;

my $intention2 = NewIntention ( 'test1d' ) ;
$stack = Log::Intention::IntentionStack -> unwind ("bla") ;
ok ( 2 == scalar @$stack, 'Intention stack count ok 2' ) ;

SKIP:
    {
    skip "KNOWN PROBLEM", 1 ;
    try
        {
        my $intention = NewIntention ( 'killed by death' ) ;
        die "dont do that" ;
        }
    catch
        {
        my $stack = Log::Intention::IntentionStack -> unwind ("bla") ;
        ok ( 3 == scalar @$stack , 'die does not freeze intention stack (TODO)') ;
        } ;
    }

try
    {
    my $i = NewIntention ( "test unwind in array context" ) ;
    $i -> Throw ( 'demo' ) ;
    }
catch
    {
    my ( $stack, $trace ) = Log::Intention::IntentionStack -> unwind ( "" ) ;
    # diag ($stack) ;
    ok ( 'ARRAY' eq ref $stack, "Stack is a array ref" ) ;
    ok ( ! ref $trace, "trace is a scalar" ) ;
    } ;

note ( "END" ) ;

