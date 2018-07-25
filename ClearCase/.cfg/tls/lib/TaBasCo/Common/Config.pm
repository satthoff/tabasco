package TaBasCo::Common::Config;

use strict;
use Carp;

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

use vars qw/ $pathLink $cspecLabel $nextLabelExtension
	     $toolPath $configFile $toolRoot $configFilePath %allTrigger $toolSelectLabel $configElement /;


BEGIN
  {
    $pathLink = 'path';
    $cspecLabel = 'CSPEC';
    $nextLabelExtension = '_NEXT';
    $toolRoot = '.cfg';
    $toolPath = 'tls';
    $configFile = 'config.txt';
    $configFilePath = $toolRoot . $OS::Common::Config::slash . $configFile;
    $toolSelectLabel = 'TABASCO';


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
    return undef unless( -e $main::installPath . $OS::Common::Config::slash . $TaBasCo::Common::Config::configFilePath );
    $configElement = ClearCase::Element->new(
	-pathname => $main::installPath . $OS::Common::Config::slash . $TaBasCo::Common::Config::configFilePath
	);
    return $configElement;
}

1;
