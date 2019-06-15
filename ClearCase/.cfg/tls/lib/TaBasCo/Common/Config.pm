package TaBasCo::Common::Config;

use strict;
use Carp;
use File::Basename;
use Cwd;

use OS::Common::Config;
use Log;
use ClearCase;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
   $VERSION   = '0.99';
   require Exporter;

   @ISA = qw(Exporter);

   @EXPORT_OK = qw(
      VOB_BASE
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );
} # sub BEGIN()

use vars qw/ $pathLink $cspecLabel $nextLabelExtension $base $myVob $baselineLink
	     $toolPath $configFile $toolRoot $configFilePath %allTrigger $toolSelectLabel $configElement
    $baselineLink # name of hyperlinks connecting a release (lbtype)  with a task (brtype) -> release is baseline of task
    $taskLink     # name of hyperlinks connecting a task (brtype) with the Vob replica -> brtype registered as task
    $firstReleaseLink
    $nextReleaseLink
    $floatingReleaseExtension
    /;


BEGIN {
    $baselineLink = 'taskBaseline';
    $taskLink = 'registeredTask';
    $firstReleaseLink = 'taskFirstRelease';
    $nextReleaseLink = 'taskNextRelease';
    $floatingReleaseExtension = '_NEXT';
    $floatingReleaseLink = 'floatingReleaseLink';
    
      $pathLink = 'TabascoPath';
      $baselineLink = 'TabascoBaseline';
      $cspecLabel = 'CSPEC';
      $nextLabelExtension = '_NEXT';
      $toolRoot = '.cfg';
      $toolPath = 'tls';
      $configFile = 'config.txt';
      $toolSelectLabel = 'TABASCO';
      $base = File::Basename::dirname (File::Basename::dirname ( Cwd::abs_path( File::Basename::dirname $0 ) ) );
      $configFilePath = $base . $OS::Common::Config::slash . $configFile;

    $myVob = $ClearCase::Common::Config::myHost->getRegion()->getVob( File::Basename::dirname ( $base ) );


    %allTrigger = (
                    'remove_empty_branch' => {
                                               'element'  => 1,
                                               'all'      => 1,
                                               'execu' => '/opt/rational/clearcase/bin/Perl /view/$CLEARCASE_VIEW_TAG$CLEARCASE_VOB_PN/' . "$toolRoot/tls/trg/remove_empty_branch.txt",
                                               'execw' => "ccperl \\\\view\\\%CLEARCASE_VIEW_TAG\%\%CLEARCASE_VOB_PN\%\\$toolRoot\\tls\\trg\\remove_empty_branch.txt",
                                               'ops'   => '-pos uncheckout,rmbranch,rmver'
                                             },
                    'apply_config_label'  => {
                                               'element'  => 1,
                                               'all'      => 1,
                                               'execu' => '/opt/rational/clearcase/bin/Perl /view/$CLEARCASE_VIEW_TAG$CLEARCASE_VOB_PN/' . "$toolRoot/tls/trg/applyConfigLabel.pl",
                                               'execw' => "ccperl \\\\view\\\%CLEARCASE_VIEW_TAG\%\%CLEARCASE_VOB_PN\%\\$toolRoot\\tls\\trg\\applyConfigLabel.pl",
                                               'ops'   => '-pos checkin'
                                             },
                    'control_config'      => {
                                               'element'  => 1,
                                               'all'      => 0,
                                               'execu' => '/opt/rational/clearcase/bin/Perl /view/$CLEARCASE_VIEW_TAG$CLEARCASE_VOB_PN/' . "$toolRoot/tls/trg/Modify.pl",
                                               'execw' => "ccperl \\\\view\\\%CLEARCASE_VIEW_TAG\%\%CLEARCASE_VOB_PN\%\\$toolRoot\\tls\\trg\\Modify.pl",
                                               'ops'   => '-pre checkin,checkout',
                                               'att'   => 1
                                             },
                    'post_control_config'      => {
                                               'element'  => 1,
                                               'all'      => 0,
                                               'execu' => '/opt/rational/clearcase/bin/Perl /view/$CLEARCASE_VIEW_TAG$CLEARCASE_VOB_PN/' . "$toolRoot/tls/trg/Modify2.pl",
                                               'execw' => "ccperl \\\\view\\\%CLEARCASE_VIEW_TAG\%\%CLEARCASE_VOB_PN\%\\$toolRoot\\tls\\trg\\Modify2.pl",
                                               'ops'   => '-pos checkout',
                                               'att'   => 1
                                             }
                  );
  }

my $configElement = undef;

sub getConfigElement {
    
    return $configElement if( $configElement );

    require ClearCase::Common::Config;
    my $view = $ClearCase::Common::Config::myHost->currentView();
    unless( $view ) {
	Die( [ "No view context set in TaBasCo::Common::Config." ] );
    }
    unless( -e $TaBasCo::Common::Config::configFilePath ) {
	ClearCase::checkout(
	    -argv => $TaBasCo::Common::Config::base
	    );
	ClearCase::mkelem(
	    -eltype   => 'text_file',
	    -nocheckout => 1,
	    -argv => $TaBasCo::Common::Config::configFilePath
	    );
    }
    $configElement = ClearCase::Element->new(
	-pathname => $TaBasCo::Common::Config::configFilePath
	);
    return $configElement;
}

1;
