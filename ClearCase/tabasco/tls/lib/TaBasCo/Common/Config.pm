package TaBasCo::Common::Config;

use strict;
use Carp;
use File::Basename;
use Cwd;

use OS::Common::Config;
use CLI::Config;
use Log;
use ClearCase;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
   $VERSION   = '0.01';
   require Exporter;

   @ISA = qw(Exporter);

   @EXPORT_OK = qw(
      VOB_BASE
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );
} # sub BEGIN()

use vars qw/
    $base
    $myVob
    $toolPath
    $configFile
    $toolRoot
    $configFilePath
    $configElement
    $nextLabelExtension
    $pathLink
    $baselineLink
    $taskLink
    $firstReleaseLink
    $nextReleaseLink
    $floatingReleaseExtension
    $floatingReleaseLink
    $myTaskLink
    $cspecDelimiter
    $taskNamePrefix
    $configurationNamePrefix
    $maintenanceTask
    $fullReleaseFlag
    $installRoot

    @allHlTypes
    @allLbTypes
    @allAtTypes
    %allTrigger
    /;


BEGIN {
    $taskNamePrefix = 'tsk_';
    $configurationNamePrefix = 'cfg_';
    my $tabascoPrefix = 'tabasco_';
    $baselineLink = $tabascoPrefix . 'TaskBaseline';
    $taskLink = $tabascoPrefix . 'RegisteredTask';
    $firstReleaseLink = $tabascoPrefix . 'TaskFirstRelease';
    $nextReleaseLink = $tabascoPrefix . 'TaskNextRelease';
    $floatingReleaseExtension = '_NEXT';
    $floatingReleaseLink = $tabascoPrefix . 'FloatingReleaseLink';
    $myTaskLink = $tabascoPrefix . 'MemberOfTask';
    $cspecDelimiter = '#-------------------------------------------------------------------------------------';
    $pathLink = $tabascoPrefix . 'Path';
    $fullReleaseFlag = $tabascoPrefix . 'FullRelease';
    $nextLabelExtension = '_NEXT';
    $toolRoot = 'tabasco';
    $maintenanceTask = 'tabasco';
    $toolPath = 'tls';
    $configFile = 'config.txt';
    $base = File::Basename::dirname (File::Basename::dirname ( Cwd::abs_path( File::Basename::dirname $0 ) ) );
    $configFilePath = $base . $OS::Common::Config::slash . $configFile;

    $myVob = $ClearCase::Common::Config::myHost->getRegion()->getVob( File::Basename::dirname ( $base ) );

    $installRoot = $myVob->getRootElement()->getNormalizedPath() . $OS::Common::Config::slash . $toolRoot;

    @allHlTypes = ( $baselineLink, $taskLink, $firstReleaseLink, $nextReleaseLink, $floatingReleaseLink, $myTaskLink, $pathLink );
    
    @allLbTypes = ();

    @allAtTypes = ( $fullReleaseFlag );

    my $myVobTag = $myVob->getTag();
    %allTrigger = (
                    'remove_empty_branch' => {
                                               'element'  => 1,
                                               'all'      => 1,
                                               'execu' => '/opt/rational/clearcase/bin/Perl /view/$CLEARCASE_VIEW_TAG' . "$myVobTag/$toolRoot/tls/trg/remove_empty_branch.txt",
                                               'execw' => "ccperl \\\\view\\\%CLEARCASE_VIEW_TAG\%$myVobTag\\$toolRoot\\tls\\trg\\remove_empty_branch.txt",
                                               'ops'   => '-pos uncheckout,rmbranch,rmver'
                                             },
                    'apply_config_label'  => {
                                               'element'  => 1,
                                               'all'      => 1,
                                               'execu' => '/opt/rational/clearcase/bin/Perl /view/$CLEARCASE_VIEW_TAG' . "$myVobTag/$toolRoot/tls/trg/applyConfigLabel.pl",
                                               'execw' => "ccperl \\\\view\\\%CLEARCASE_VIEW_TAG\%$myVobTag\\$toolRoot\\tls\\trg\\applyConfigLabel.pl",
                                               'ops'   => '-pos checkin'
                                             }
                  );
  }

my $configElement = undef;

sub getConfigElement {
    Debug( [ '', __PACKAGE__ .'::getConfigElement' ] );
    
    return $configElement if( $configElement );

    require ClearCase::Common::Config;
    my $view = $ClearCase::Common::Config::myHost->getCurrentView();
    unless( $view ) {
	Die( [ "No view context set in TaBasCo::Common::Config." ] );
    }
    unless( -e $TaBasCo::Common::Config::configFilePath ) {
	Transaction::start( -comment => 'create TABASCO config element' );
	ClearCase::checkout(
	    -argv => $TaBasCo::Common::Config::base
	    );
	ClearCase::mkelem(
	    -eltype   => 'text_file',
	    -nocheckout => 1,
	    -argv => $TaBasCo::Common::Config::configFilePath
	    );
	Transaction::commit();
    }
    $configElement = ClearCase::Element->new(
	-pathname => $TaBasCo::Common::Config::configFilePath
	);
    return $configElement;
}

sub gmtTimeString {
    Debug( [ '', __PACKAGE__ .'::gmtTimeString' ] );
    my @gmt = gmtime();
    my @month = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    my $year = $gmt[5] + 1900;
    my $timeString = sprintf( "%s.%s.%s-GMT-%d.%d.%d", $gmt[3], $month[ $gmt[4] ], $year, $gmt[2], $gmt[1], $gmt[0]);
    return $timeString;
}

sub cspecHeader {
    my $config_spec = shift;
    Debug( [ '', __PACKAGE__ .'::cspecHeader' ] );

    push @$config_spec, '#';
    push @$config_spec, '# ATTENTION ! Never change anything in this config spec !';
    push @$config_spec, '# It has been generated by the TABASCO tool.';
    push @$config_spec, '#';
    push @$config_spec, "# TABASCO Version: $CLI::Config::VERSION";
    push @$config_spec, '# Copyright (C) 2004 - 2019  by Uwe Satthoff (satthoff@icloud.com)';
    push @$config_spec, '#';
    push @$config_spec, '# Cspec created : ' . &TaBasCo::Common::Config::gmtTimeString();
    push @$config_spec, $TaBasCo::Common::Config::cspecDelimiter;
    
    return;
}

#sub pathVisible {
#    my $path = shift;
#
#    my $view = $ClearCase::Common::Config::myHost->getCurrentView();
#    Transaction::start( -comment => "set correct config spec to check path existence in release " . $self->getName() );
#    my $cspecFile = $self->getVXPN();
#    open FD, "$cspecFile";
#    my @cspec = <FD>;
#    close FD;
#    grep chomp, @cspec;
#    # delete all carrige return from contents,
#    # which will be added by changes edited on Windows
#    grep s/\r//g, @cspec;
#    $view->setConfigSpec( \@cspec );
#    my $ret = ( -e $path );
#    Debug( [  __PACKAGE__ . "::pathVisible >$path<" ] );
#    if( $ret )
#      {
#	Debug( [ '    path is visible' ] );
#      }
#    else
#      {
#	Debug( [ '    path is NOT visible' ] );
#      }
#    Transaction::rollback(); # reset the config spec
#    return $ret;
#  }
#
1;
