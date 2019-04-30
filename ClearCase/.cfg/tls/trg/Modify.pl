#
# this version has been created to be attached to activity tabasco-default-second,
# where the previous version of this file is attached to activity tabaso-default.
# Purpose: test UCM deliver of these two activities in the right sequence.
#

# pre checkout/checkin trigger to be attached to configuration control file
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


sub createNewTask
  {
    my $baseline = shift;
    my $ui       = shift;

    my $branch = $ui->ask( -question => 'Request for new task. Enter task name:' );
    chomp $branch;
    unless( $branch )
      {
        Log::Die( [ "NO TASK NAME HAS BEEN SPECIFIED:" ] );
      }

    my $newPath = '';
    $branch = lc $branch;

    Transaction::start( -comment => "create new task / branch $branch $$ :  $ENV{ CLEARCASE_PPID }" );
    my $newTask = TaBasCo::Task->create(
					-baseline => $baseline,
					-name     => $branch
				       );
    if( $ui->askYesNo( -question => 'Do you want the new task only to work on sub-directories of its parent?', -default  => 'no' ) )
      {
	# here we have to guarantee that the config spec of the task's baseline  is set,
	# otherwise the selection of a sub directory won't work.
	Transaction::start( -comment => "set correct config spec for directory selection" );
	my $currentView = ClearCase::View( "$ENV{CLEARCASE_VIEW_TAG}" );
	my $cspecFile = $baseline->getVXPN();
	open FD, "$cspecFile";
	my @cspec = <FD>;
	close FD;
	grep chomp, @cspec;
	# delete all carrige return from contents,
	# which will be added by changes edited on Windows
	grep s/\r//g, @cspec;
	$currentView->setConfigSpec( \@cspec );

	Transaction::start( -comment => "intermediate transaction to be able to roll back config spec setting" );
	my @parentPaths = @{ $newTask->getParent()->getPath() };
	if( $#parentPaths > 0 )
	  {
	    my @mes = @parentPaths;
	    grep s/$/\n/, @mes;
	    $ui->okMessage( "The parent task has more than 1 path attached.\n\n@mes\nWe will step through all these subtrees, one after the other" );
	  }
	foreach my $pathsRoot ( @parentPaths )
	  {
	    while( $newPath = $ui->selectDirectory( -question  => 'Select a directory to be used for your new task. Abort to finish.', -directory => $pathsRoot ) )
	      {
		if( $newPath ne ''  )
		  {
		    my $parentPath = $pathsRoot;
		    $parentPath =~ s/\\/\//g;
		    $newPath =~ s/\\/\//g;
		    my $i = index( $newPath, $parentPath);
		    if( ($i == 0) and (length( $newPath ) >= length( $parentPath )) )
		      {
			$newTask->mkPath( $newPath );
		      }
		    else
		      {
			$ui->okMessage( "The path must be a subpath of the parent path." );
		      }
		  }
	      }
	  }
	Transaction::release(); # keep all actions done
	Transaction::rollback(); # reset the config spec
      }
    Transaction::release(); # we do not want to checkout version 0 on new task / branch
    return $branch;
  }

sub setConfigSpec
  {
    my $cspecFile = shift;
    my $ui        = shift;

    open FD, "$cspecFile";
    my @cspec = <FD>;
    close FD;
    grep chomp, @cspec;

    # delete all carrige return from contents,
    # which will be added by changes edited on Windows
    grep s/\r//g, @cspec;

    my $targetView = $ui->ask( -question => 'Enter view name or pattern for view selection:' );
    chomp $targetView;
    ClearCase::lsview( -short => 1 );
    my @views = ClearCase::getOutput();
    grep chomp, @views;
    if( $targetView )
      {
	@views = grep m/$targetView/, @views;
      }
    if( @views )
      {
	$targetView = $ui->selectFromList( -question => 'Select target view!',  -list     => \@views,  -unique   => 1 );
	unless( $targetView )
	  {
	    $ui->okMessage( "No view selected." );
	    return;
	  }
      }
    else
      {
	$ui->okMessage( "No view found." );
	return;
      }
    my $view = ClearCase::View( "$targetView" );
    if( $view->setConfigSpec( \@cspec ) )
      {
	$ui->okMessage( "Successfully set config spec in view $targetView." );
      }
    else
      {
	$ui->okMessage( "Setting config spec failed in view $targetView." );
      }
  }



#-- MAIN --
if( defined( $ENV{ 'SDEV_VERBOSITY' } ) )
  {
    # in case of any failure of a cleartool operation
    # we will see the complete trace
    Log::setVerbosity( 'DEBUG' );
  }

# start a transaction to be able to rollback any modifications
# in case of any failure in a cleartool operation
Transaction::start( -comment => "pre $ENV{ CLEARCASE_OP_KIND } $ENV{ CLEARCASE_XPN } $$ :  $ENV{ CLEARCASE_PPID }" );

# load the user interface
my $ui = TaBasCo::UI->new();

# declare variable to hold release in focus
my $relFocus = undef;

# All configuration activities are initiated
# by the checkout, checkin and uncheckout of dedicated versions
# in the version tree of the config.txt file.
#
if( $ENV{ CLEARCASE_OP_KIND } eq 'checkout' )
  {
    # load the release in focus, which is the element version to be checked out
    $relFocus = TaBasCo::Release->new( -pathname => $ENV{ CLEARCASE_XPN } );

    my $actVersion  = $relFocus->getVersionString();
    my $lastVersion = $relFocus->getTask()->getLatestVersion()->getVersionString();
    my $zeroVersion = $relFocus->getTask()->getZeroVersion()->getVersionString();
    my $actBranch   = File::Basename::dirname( $actVersion  );
    my $lastBranch  = File::Basename::dirname( $lastVersion );
    if( $actVersion  ne $lastVersion and $actBranch eq $lastBranch )
      {
	# the version to be checked out is not the latest version on current branch
	my $cspecVersion = $relFocus->getTask()->getLabeledVersion( $TaBasCo::Config::cspecLabel )->getVersionString();
	my @actions = ();
	push @actions, 'create_new_task' if( $actVersion ne $cspecVersion );
	push @actions, 'set_config_spec';
	my $action = $ui->selectFromList( -question => 'What do you want to do?',  -list     => \@actions,  -unique   => 1 );
	if( $action ne 'create_new_task' and $action ne 'set_config_spec' )
	  {
	    Log::Die( [ 'no valid action has been selected.' ] );
	  }
	if( $action eq 'set_config_spec' )
	  {
	    # versions of the config file always contain a valid config spec
	    setConfigSpec( $relFocus->getVXPN(), $ui );
	  }
	else
	  {
	    # the only other sensefull configuration activity
	    # in case the version to be checked out is not the latest
	    # is the creation of a new task = branch, branching off from the version in focus
	    my $task = createNewTask( $relFocus, $ui );
	    $ui->okMessage( "Successfully created new task (refresh view in vtree browser)." );
	  }
	# we have to cancel the requested checkout.
	# unfortunately we can not suppress the error messages, which will be generated because
	# the trigger rejected the checkout operation
	Transaction::release();
	exit 1;
      }
    elsif( $zeroVersion ne $lastVersion )
      {
	# the version to be checked out is the latest on branch.
	# here we have more alternatives for the configuration activity:
	# prepare the creation of a new release on checkin, means let checkout proceed
	# create a new task based on the version in focus, do not let checkout proceed
	# set config spec of a view, if the version in focus is the CSPEC version, do not let checkout proceed
	my $cspecVersion = $relFocus->getTask()->getLabeledVersion( $TaBasCo::Config::cspecLabel )->getVersionString();
	my @actions = ();
	push @actions, 'start_release_creation';
	push @actions, 'create_new_task' if( $actVersion ne $cspecVersion );
	push @actions, 'set_config_spec';
	my $action = $ui->selectFromList( -question => 'What do you want to do?',  -list     => \@actions,  -unique   => 1 );
	if( $action ne 'create_new_task' and $action ne 'start_release_creation' and $action ne 'set_config_spec' )
	  {
	    Log::Die( [ 'no valid action has been selected.' ] );
	  }
	if( $action eq 'create_new_task' )
	  {
	    my $task = createNewTask( $relFocus, $ui );
	    $ui->okMessage( "Successfully created new task (refresh view in vtree browser)." );
	    # we have to cancel the requested checkout.
	    # unfortunately we can not suppress the error messages, which will be generated because
	    # the trigger rejected the checkout operation
	    Transaction::release();
	    exit 1;
	  }
	elsif( $action eq 'set_config_spec' )
	{
	    setConfigSpec( $relFocus->getVXPN(), $ui );
	    # we have to cancel the requested checkout.
	    # unfortunately we can not suppress the error messages, which will be generated because
	    # the trigger rejected the checkout operation
	    Transaction::release();
	    exit 1;
	}
	else
	{
	    # create unique file in /tmp which will be checked in the post checkout trigger
	    # for now works only on UNIX
	    Debug( [ "creating file /tmp/tabasco.$ENV{ CLEARCASE_PPID }" ] );
	    system( "touch /tmp/tabasco.$ENV{ CLEARCASE_PPID }" );
	}
      }
  }
elsif( $ENV{ CLEARCASE_OP_KIND } eq 'checkin' )
  {
    # because the to be checked in version does not exist yet
    # the configuration in focus is the checkedout version
    $relFocus = TaBasCo::Release->new( -pathname => $ENV{ CLEARCASE_PN } );

    my $zeroVersion = $relFocus->getTask()->getZeroVersion()->getVersionString();
    my $previousVersion = $relFocus->getPreviousVersion()->getVersionString();
    if( $zeroVersion eq $previousVersion )
      {
	# the version checked out is the version zero, means the task had been initially created
	# we have to create the task's config spec
	#
	# we have to use the config spec of the parent task
	Transaction::start( -comment => "set correct config spec for config spec creation" );
	my $currentView = ClearCase::View( "$ENV{CLEARCASE_VIEW_TAG}" );
	my $cspecFile = $relFocus->getTask()->getParent()->getLabeledVersion( $TaBasCo::Config::cspecLabel )->getVXPN();
	open FD, "$cspecFile";
	my @cspec = <FD>;
	close FD;
	grep chomp, @cspec;
	# delete all carrige return from contents,
	# which will be added by changes edited on Windows
	grep s/\r//g, @cspec;
	$currentView->setConfigSpec( \@cspec );

	Transaction::start( -comment => "task config spec creation" );
	$relFocus->getTask()->createConfigSpec( $currentView );
	Transaction::release(); # keep all actions done
	Transaction::rollback(); # reset the config spec
      }
  }
Transaction::commit();
