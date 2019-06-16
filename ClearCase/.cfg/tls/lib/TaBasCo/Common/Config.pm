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
    $myTaskLink
    /;


BEGIN {
    $baselineLink = 'taskBaseline';
    $taskLink = 'registeredTask';
    $firstReleaseLink = 'taskFirstRelease';
    $nextReleaseLink = 'taskNextRelease';
    $floatingReleaseExtension = '_NEXT';
    $floatingReleaseLink = 'floatingReleaseLink';
    $myTaskLink = 'memberOfTask';
    
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

sub cspecHeader {
    my $config_spec   = shift;

    Debug( [ '', 'BEGIN: ' . __PACKAGE__ . '::cspecHeader' ] );

    push @$config_spec, '#';
    push @$config_spec, '# ATTENTION ! Never change anything in this config spec !';
    push @$config_spec, '# It has been generated by the TABASCO tool.';
    push @$config_spec, '#';
    push @$config_spec, "# TABASCO Version: $VERSION";
    push @$config_spec, '# Copyright (C) 2010 - 2019  by Uwe Satthoff (satthoff@icloud.com)';
    push @$config_spec, '#';
    push @$config_spec, '# Date : ' . $self->gmtTimeString();
    push @$config_spec, '#-------------------------------------------------------------------------------------';

    my $toolRoot = File::Basename::dirname( TaBasCo::Common::Config::getConfigElement()->getNormalizedPath() );
    my $rootCspec = TaBasCo::Common::Config::getConfigElement()->getCspecPath();
    $rootCspec =~ s/\/\.\.\.$//;
    my $toolCspec = ClearCase::Element->new( -pathname => $toolRoot . $OS::Common::Config::slash . $TaBasCo::Common::Config::toolPath )->getCspecPath();
    push @$config_spec, 'element -directory ' . File::Basename::dirname( $rootCspec ) . " $TaBasCo::Common::Config::toolSelectLabel -nocheckout";
    push @$config_spec, 'element -file ' . $rootCspec . " CHECKEDOUT";
    push @$config_spec, 'element -file ' . $rootCspec . " /main/LATEST";
    push @$config_spec, 'element ' . $toolCspec . " $TaBasCo::Common::Config::toolSelectLabel -nocheckout";

}

sub createConfigSpec {
    my $view = shift; # object of class ClearCase::View

    my @config_spec = ();
    push @config_spec, 'element * CHECKEDOUT';

    $self->cspecHeader( \@config_spec );

    push @config_spec, '#-------------------------------------------------------------------------------------';
    push @config_spec, '# BEGIN  Task : ' . $self->getName();
    my $pT = 'NONE';
    if( $self->getParent() )
      {
	$pT = $self->getParent()->getName();
      }
    push @config_spec, '# Parent Task : ' . $pT;
    push @config_spec, '#-------------------------------------------------------------------------------------';

    my $act = $self;
    my $baseline = $act->getBaseline();
    unless( $baseline )
      {
	foreach my $p ( @{ $act->getCspecPath() } )
	  {
	    push @config_spec, "element $p /" . $act->getName() . "/LATEST";
	  }
      }
    else
      {
	foreach my $p ( @{ $act->getCspecPath() } )
	  {
	    push @config_spec, "element $p .../" . $act->getName() . "/LATEST";
	  }
	push @config_spec, "mkbranch " . $act->getName();
	my @paths = @{ $act->getPath() };
	my @cspecPaths = @{ $act->getCspecPath() };
	while( my $p = shift  @paths and  my $cp = shift @cspecPaths  )
	  {
	    Debug( [ "mkbranch: >$p< >$cp<" ] );
	    while( $baseline )
	      {
		if( $baseline->pathVisible( $p, $view ) )
		  {
		    push @config_spec, "element $cp " . $baseline->getName();
		  }
		$baseline = $baseline->getPrevious();
	      }
	    $baseline = $act->getBaseline();
	  }
	$baseline = $act->getBaseline();
	foreach my $p ( @{ $act->getCspecPath() } )
	  {
	    push @config_spec, "element $p /main/0";
	  }
	push @config_spec, "end mkbranch " . $act->getName();
	while( $baseline )
	  {
	    foreach my $p ( @{ $baseline->getTask()->getCspecPath() } )
	      {
		push @config_spec, "element " . $p . ' ' . $baseline->getName() . " -nocheckout";
	      }
	    $baseline = $baseline->getPrevious();
	  }
      }

    push @config_spec, '# END   Task : ' . $self->getName();
    push @config_spec, '#-------------------------------------------------------------------------------------';
    push @config_spec, 'element * /main/0 -nocheckout';
    grep chomp, @config_spec;

    my $file = $self->getNormalizedPath();

    ClearCase::lscheckout(
	-argv => $file,
	-short => 1
	);
    my @erg = ClearCase::getOutput();
    grep chomp, @erg;
    unless( @erg ) {
	Transaction::start( -comment => 'checkout config element for new task config spec' );
	ClearCase::checkout(
	    -argv => $file
	    );
    }
    open FD, ">$file";
    foreach ( @config_spec )
      {
        print FD "$_\n";
      }
    close FD;
    unless( @erg ) {
	Transaction::commit();
    }

    my $cspecRelease =  TaBasCo::Release->new( -pathname => $self->getNormalizedPath() );
    $cspecRelease->applyName( $TaBasCo::Common::Config::cspecLabel );
}

sub createCspecBlock
  {
    my $self = shift;
    my $actRelease = shift;
    my $view = shift; # object of class ClearCase::View

    my @config_spec = ();

    $self->cspecHeader( \@config_spec );

    my $theRelease = $actRelease;
    push @config_spec, '#-------------------------------------------------------------------------------------';
    push @config_spec, '# BEGIN Release : ' . $actRelease->getName();
    push @config_spec, '# Task          : ' . $self->getName();
    my $parent = $self->getParent();
    if( $parent )
      {
        push @config_spec, '# Parent task   : ' . $self->getParent()->getName();
      }
    else
      {
        push @config_spec, '# Parent task   : NONE';
      }
    while( $actRelease )
      {
	foreach my $p ( @{ $actRelease->getTask()->getCspecPath() } )
	  {
	    push @config_spec, "element " . $p . ' ' . $actRelease->getName() . " -nocheckout";
	  }
	$actRelease = $actRelease->getPrevious();
      }
    push @config_spec, '# END   Release : ' . $theRelease->getName();
    push @config_spec, '#-------------------------------------------------------------------------------------';
    return @config_spec;
  }


1;
