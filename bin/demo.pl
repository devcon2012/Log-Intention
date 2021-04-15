#!/usr/bin/perl

# Intention logging sample program
# tries to vaguely mimic sshd behaviour

use strict ;
use warnings ;

use lib qw( /home/klaus/src/owngit/Log-Intention/lib ) ;

use Try::Tiny;

use Log::Intention ;
use Log::Intention::IntentionStack ;
use Log::Intention::LogTarget::JournalD ;
use Log::Intention::LogTarget::Log4perl ;

BEGIN
    {
    my $target = Log::Intention::LogTarget::Log4perl -> new ;
    $target -> set_meta_value ("LOG_SRC" , "demo-IntentionLog" ) ;
    Log::Intention::IntentionStack -> LogTarget ( $target ) ;
    # use journalctl LOG_SRC=demo-IntentionLog -f to follow the log output produced
    }

sub negotiate_authentication
    {
    # push a new intention on the intention stack, which will cause a log entry
    # as to where/when this happened
    my $i = Log::Intention -> new( { what => "negotiate authentication"}  ) ;

    my $rnd = int rand 10 ;

    my $auth = '' ;

    $auth = 'pw'
        if ( $rnd > 2 ) ;

    $auth = 'rsa'
        if ( $rnd > 6 ) ;

    if ( $auth )
        {
        # log what happened
        $i -> Log ( "rnd val $rnd leads to auth $auth" ) ;
        }
    else
        {
        # Uups .. houston, we have a problem
        $i -> Throw ( "rnd val $rnd leads to no agreement on any auth method" ) ;
        }

    # the intention is destroyed as it goes out of scope
    # causing another log entry about its completion

    return $auth;
    }

sub authenticate
    {
    my ($auth) = @_ ;
    my $i = Log::Intention -> new( { what => "authenticate using $auth"}  ) ;

    my $user = 'jane.doe' ;

    my $rnd = int rand 10 ;
    if ( $rnd > 4 )
        {
        $i -> Log ( "Authenticated user $user" ) ;
        return $user ;
        }
    else
        {
        $i -> Log ( "$user failed to provide auth $auth", 'E' ) ;
        }
    }

sub work
    {
    my ($user) = @_ ;
    my $i = Log::Intention -> new( { what => "$user logged in and working"}  ) ;

        {
        my $i = Log::Intention -> new( { what => "Spawned sub-shell 1"}  ) ;

        # channel opens might interleave, so creating an intention makes no sense
        $i -> Log ("opened channel to 192.168.188.13:666") ;
        $i -> Log ("opened channel to 192.168.27.99:22") ;
        $i -> Log ("closed channel to 192.168.188.13:666") ;
        $i -> Log ("closed channel to 192.168.27.99:22") ;
        }

    # access to a host which is down is just an error..
    $i -> Log ("opened a channel to 127.0.0.1:1234") ;
    $i -> Log ("host 127.0.0.1:1234 not reachable", 'E') ;

        {
        my $i = Log::Intention -> new( { what => "Spawned sub-shell 2"}  ) ;
        $i -> Log ("opened channel to 192.168.188.13:666") ;
        $i -> Log ("closed channel to 192.168.188.13:666") ;
        }

    # access to a host which is denied will get you kicked ...
    $i -> Throw ("denied opening a channel to 127.0.0.1:4321")
        if ( 5 < rand 10 ) ;

    }

# main program

my $i = Log::Intention -> new( { what => "Demo"}  ) ;

my $result = 'without errors' ;

    try
        {
        my $auth = negotiate_authentication ;
        my $user = authenticate($auth) ;
        work( $user )
            if ( $user ) ;
        }
    catch
        {
        my $e = $_ ;
        # my $stack = Log::Intention::IntentionStack -> unwind ("Intention trace") ;
        Log::Intention::IntentionStack -> thaw ;
        $result = "ERROR: " . $e -> message ;
        } ;

$i -> Log ("done ($result).") ;
