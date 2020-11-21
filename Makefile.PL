#
# Log::Intention - intention logging for perl
#
#   (c) Klaus Ramstöck klaus@ramstoeck.name 2020
#
# You can use and distribute this software under the same conditions as perl
#

use 5.026001;
use ExtUtils::MakeMaker;

use File::Find ;
use Cwd ;

our @modules ;

sub wanted
    {
    push @modules, $File::Find::name
        if ( /\.p[ml]$/ ) ;
    push @modules, $File::Find::name
        if ( /\.t$/ ) ;
    }

our @manifest ;
sub UpdateManifest
    {
    push @manifest, glob '*.md' ;
    push @manifest, glob '*.pl' ;
    push @manifest, 'LICENSE' ;
    push @manifest, 'Makefile.PL' ;
    push @manifest, 'Changes' ;
    push @manifest, '.gitignore' ;


    find ( sub { push @manifest, $File::Find::name if ( /\.p[lm]$/ ) ; },
            'lib', 'bin'
            );

    find ( sub { push @manifest, $File::Find::name if ( /\.t$/ ) ; },
            't'
            );

    open ( my $fh, ">", "MANIFEST.new")
        or die "cannot open MANIFEST.new: $!";
    print $fh join ("\n", sort { fc($a) cmp fc($b) } @manifest);
    print $fh "\n";
    close $fh ;
    system ("echo 'MANIFEST changes:' ; diff MANIFEST MANIFEST.new") ;
    system ("diff MANIFEST.new MANIFEST")
        or system ("rm MANIFEST.new");
    }

sub CritiqueModules
    {
    find(\&wanted, 'lib' );

    print STDERR "Run perlcritic on each module:\n";

    foreach my $m (@modules)
        {
        system("perlcritic --profile perlcriticrc $m")
            and print STDERR "ERROR in $m\n" ;
        }

    @modules = () ;
    find(\&wanted, 't' );

    print STDERR "Run perlcritic on each test:\n";

    foreach my $m (@modules)
        {
        system("perlcritic --profile perlcriticrc --theme tests $m")
            and print STDERR "ERROR in $m\n" ;
         }

    }

sub PrintInfo
    {
    print "New to this? Run some tests verbose:\n" ;
    print "make test TEST_VERBOSE=1 TEST_FILES='t/test.t'\n" ;
    print "Run one test for debugging:\n" ;
    print "make testdb TEST_FILE=t/test.t\n" ;
    }

WriteMakefile(
    NAME              => 'Log::Intention',
    VERSION_FROM      => 'lib/Log/Intention.pm',
    PREREQ_PM         => {
                        'Moose'                  => 2,
                        'Moose::Role'            => 1,
                        'MooseX::ClassAttribute' => 0.2,
                        'Try::Tiny'              => 0.28,
                         } ,
    ABSTRACT          => 'Intention logging for perl',
    AUTHOR            => 'Klaus Ramstöck <klaus@ramstoeck.name>',
    LICENSE           => 'perl',
) ;

CritiqueModules() ;

UpdateManifest() ;

PrintInfo() ;
