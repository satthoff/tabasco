
# post checkout trigger to be attached to configuration control file
# of the TaBasCo installation
use strict;

# execute this BEGIN block as the very first set of statements
# to define OS specific parameters and to include the lib
# directory to the Perl INC list.
use vars qw/
	    $trash $silent $slash $qslash $base $ccp_newline $tempDir
	    /;
my @INCL_LIB = ();
BEGIN {

  $base = "";
  $ccp_newline = ""; # Clearprompt newline option
  $tempDir = "/tmp";
  if ( defined $ENV{OS} )
    {
      # we are on a Windows platform
      $base = "\\\\view\\$ENV{CLEARCASE_VIEW_TAG}$ENV{CLEARCASE_VOB_PN}";
      push @INCL_LIB, ( "$base\\.cfg\\tls\\lib" );
      $ccp_newline = '-newline';
      $tempDir = $ENV{TEMP};
    }
  else
    {
      # we are on a UNIX platform
      $base = "//view/$ENV{CLEARCASE_VIEW_TAG}$ENV{CLEARCASE_VOB_PN}";
      push @INCL_LIB, ( "$base/.cfg/tls/lib" );

      # insert privately installed IPC::ChildSafe path for demonststration @ ASML
      #push @INCL_LIB, '/home/usatthof/myPerl/lib/site_perl/5.8.4/x86_64-linux';
      
      # insert lib path for CtCmd
      #push @INCL_LIB, '/sdev/user/lib/site_perl/5.8.4/x86_64-linux';

    }
  unshift @INC, @INCL_LIB;
}

use lib '/sdev/user/lib/site_perl';
use Log;
use TaBasCo;


sub createNewRelease
  {
    my $task = shift;
    my $releaseName = shift;
    my $view = shift; # object of class ClearCase::View

    $task->createNewRelease( $releaseName, $view );
  }


#-- MAIN --

if( defined( $ENV{ 'SDEV_VERBOSITY' } ) )
  {
     # in case of any failure of a cleartool operation
     # we will see the complete trace
     Log::setVerbosity( 'DEBUG' );
  }

# check for command release creation from pre checkout trigger
unless( -e '/tmp/tabasco.' . $ENV{ CLEARCASE_PPID } ) {
    Debug( [ "File /tmp/tabasco.$ENV{ CLEARCASE_PPID } does not exist - exit trigger." ] );
    exit 0;
} else {
    Debug( [ "File /tmp/tabasco.$ENV{ CLEARCASE_PPID } exists = the actual checkout was initiated from start_release_creation." ] );
    unlink "/tmp/tabasco.$ENV{ CLEARCASE_PPID }";
}

# start a transaction to be able to rollback any modifications
# in case of any failure in a cleartool operation
Transaction::start( -comment => "post $ENV{ CLEARCASE_OP_KIND } $ENV{ CLEARCASE_PN } $$ :  $ENV{ CLEARCASE_PPID }" );

# load the user interface
my $ui = TaBasCo::UI->new();

# declare variable to hold release in focus
my $relFocus = undef;

# the configuration in focus is the checkedout version
$relFocus = TaBasCo::Release->new( -pathname => $ENV{ CLEARCASE_PN } );

my $releaseName = $relFocus->getTask()->nextReleaseName();
my $relName = $ui->ask( -question => 'Enter a name for the new release or accept the proposal:', -proposal => $releaseName );
chomp $relName;
$relName =~ s/\s+/_/;
$relName =~ s/\:/\./;
unless( $relName )
{
    $relName = $releaseName;
}
$relName = uc $relName;
unless( $ui->askYesNo( -question => "Do you want to create now the new release $relName ?", -default  => 'yes' ) )
{
    $ui->okMessage( "Command start_release_creation cancelled, but cannot do the uncheckout myself. Please uncheckout yourself." );
    Transaction::commit();
    exit -1;
}
	    
while( $ui->askYesNo( -question => 'Do you want to draw a merge arrow from another release before creating the new release in your task?', -default  => 'no' ) )
{
    my $cspecFile = $ui->selectFile( -question => 'From which configuration you want to draw a merge arrow?', -directory => $ENV{ CLEARCASE_PN } . '@@' );
    if( $cspecFile )
    {
	my $select = $cspecFile;
	$select =~ s/.*\@\@(.*)$/$1/;
	ClearCase::merge( -topath => $ENV{ CLEARCASE_PN }, -nodata => 1, -fromversion => $select );
    }
}

# we have to use the config spec of the release's  task
Transaction::start( -comment => "set correct config spec for release creation" );
my $currentView = ClearCase::View( "$ENV{CLEARCASE_VIEW_TAG}" );
my $cspecFile = $relFocus->getTask()->getLabeledVersion( $TaBasCo::Common::Config::cspecLabel )->getVXPN();
open FD, "$cspecFile";
my @cspec = <FD>;
close FD;
grep chomp, @cspec;
# delete all carrige return from contents,
# which will be added by changes edited on Windows
grep s/\r//g, @cspec;
$currentView->setConfigSpec( \@cspec );

Transaction::start( -comment => "release creation" );
createNewRelease( $relFocus->getTask(), uc $relName, $currentView );
Transaction::release(); # keep all actions done

Transaction::rollback(); # reset the config spec

Transaction::commit();
