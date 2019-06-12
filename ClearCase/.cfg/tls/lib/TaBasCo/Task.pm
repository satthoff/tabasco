package TaBasCo::Task;

use strict;
use Carp;

use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '09122014_1';
   require Exporter;
   require ClearCase::Branch;

   @ISA = qw(  Exporter Data ClearCase::BrType );

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   require Data;

   %DATA = (
       MainTask  => { CALCULATE => \&loadMainTask },
       Parent    => { CALCULATE => \&loadParent },
       Path      => { CALCULATE => \&loadPath },
       CspecPath => { CALCULATE => \&loadCspecPath },
       Baseline  => { CALCULATE => \&loadBaseline }
       );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => "ClearCase::Branch"
      );


} # sub BEGIN()

sub _init {
   my $self = shift;

   $self->SUPER::_init( -vob => $TaBasCo::Common::Config::myVob, @_ );
   return $self;
} # _init

sub create {
    my $self = shift;

   my ( $baseline, $comment, @other ) = $self->rearrange(
      [ 'BASELINE', 'COMMENT' ],
      @_ );

    unless( $baseline->exists() ) {
	Error( [ __PACKAGE__ . '::create : Baseline ' . $baseline->getName() . ' does not exist.' ] );
	return undef;
    }
    $self->SUPER::create( -comment => $comment );

    ClearCase::mkhlink(
	-hltype => $TaBasCo::Common::Config::TabascoBaseline,
	-from => $self,
	-to => $baseline
	);
    
    return $self;
}

sub loadBaseline {
    my $self = shift;

    ClearCase::describe(
	-short    => 1,
	-ahl      => $TaBasCo::Common::Config::TabascoBaseline,
	-argv => $self->getFullName()
	);
    my @result = ClearCase::getOutput();
    grep chomp, @result;
    if( $#result != 0 ) {
	Die( [ '', "incorrect number ($#result) of baseline links $TaBasCo::Common::Config::TabascoBaseline at task " . $self->getFullName(), '' ] );
    }
    # we expect the result to be a TaBasCo::Release
    my $baseline = TaBasCo::Release->new( -name => $result[0], -vob => $self->getVob() );
    unless( $baseline ) {
	Die( [ '', "Hyperlink $TaBasCo::Common::Config::TabascoBaseline on task " . $self->getFullName() . " does not point to a TaBasCo::Release in Vob " . $self->getVob()->getTag(), '' ] );
    }
    
    return $self->setBaseline( $baseline );
}


sub loadMainTask {
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {};
    bless $self, $class;

    my $mainTask = $self->new( -pathname => TaBasCo::Common::Config::getConfigElement()->getNormalizedPath() . '@@' . $OS::Common::Config::slash . 'main' );
    Die( [ '', 'Cannot load the main task.', '' ] ) unless( $mainTask );

    # loading the main task means probably to install TABASCO in my vob.
    # in this case  we have to ensure that all initializations will be done.
    unless( $TaBasCo::Common::Config::myVob->getLbType( $TaBasCo::Common::Config::toolSelectLabel ) ) {
	$TaBasCo::Common::Config::myVob->ensureLabelType( -name => uc( 'main' . $TaBasCo::Common::Config::nextLabelExtension ) );
	$TaBasCo::Common::Config::myVob->ensureLabelType( -name => $TaBasCo::Common::Config::cspecLabel, -pbranch => 1 );
	$TaBasCo::Common::Config::myVob->ensureHyperlinkType( -name => $TaBasCo::Common::Config::pathLink );
	$TaBasCo::Common::Config::myVob->ensureLabelType( -name => $TaBasCo::Common::Config::toolSelectLabel );

	# now create the hyperlink from the first Task (= branch main of the configuration file)
	# to the Vob root path element
	my $initialPathLink = ClearCase::HyperLink->new(
	    -hltype => $TaBasCo::Common::Config::myVob->getHlType( $TaBasCo::Common::Config::pathLink ),
	    -from   => $mainTask,
	    -to     => $TaBasCo::Common::Config::myVob->getRootElement()
	    );
	$initialPathLink->create();
	$mainTask->createConfigSpec( $ClearCase::Common::Config::myHost->currentView() );
	$mainTask->createNewRelease( $mainTask->nextReleaseName(), $ClearCase::Common::Config::myHost->currentView() );
    }
    return $self->setMainTask( $mainTask );
}

sub gmtTimeString
  {
    my $self = shift;

    my @gmt = gmtime();
    my @month = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    my $year = $gmt[5] + 1900;
    my $timeString = sprintf( "%s.%s.%s-GMT-%d.%d.%d", $gmt[3], $month[ $gmt[4] ], $year, $gmt[2], $gmt[1], $gmt[0]);
    return $timeString;
}

sub nextReleaseName
  {
    my $self = shift;
    return uc( $self->getName() ) . '_' . $self->gmtTimeString();
  }

sub createNewRelease
  {
    my $self = shift;
    my $releaseName = shift;
    my $view = shift; # object of class ClearCase::View

    # the existing floating release becomes the new release,
    # means we have to rename the floating release
    # and to re-create it right after
    TaBasCo::Release::renameFloatingRelease( $self, $releaseName );
    TaBasCo::Release::createFloatingRelease( $self );
    
    my $file = TaBasCo::Common::Config::getConfigElement()->getNormalizedPath();
    my $newRelease = TaBasCo::Release->new( -pathname => $file );
    $newRelease->setName( $releaseName );

    # create the configuration specification
    my @cspec = $self->createCspecBlock( $newRelease, $view );

    ClearCase::lscheckout(
	-argv => $file,
	-short => 1
	);
    my @erg = ClearCase::getOutput();
    grep chomp, @erg;
    unless( @erg ) {
	Transaction::start( -comment => 'checkout config element for new release config spec' );
	ClearCase::checkout(
	    -argv => $file
	    );
    }
    open FD, ">$file";
    foreach ( @cspec )
      {
        print FD "$_\n";
      }
    close FD;
    unless( @erg ) {
	Transaction::commit();
    }

    $newRelease->applyName( $releaseName );

    return $newRelease;
  }

sub cspecHeader
  {
    my $self = shift;
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

sub createConfigSpec
  {
    my $self = shift;
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


sub mkPath
  {
    my $self = shift;
    my $path = shift;
    ClearCase::mkhlink(
		       -hltype => $TaBasCo::Common::Config::pathLink,
		       -from   => $self->getVXPN(),
		       -to     => $path . '/.@@'
		      );
    $self->setPath( $path );
    return $self;
  }

sub loadPath
  {
    my $self = shift;

    ClearCase::describe(
                        -short    => 1,
                        -ahl      => $TaBasCo::Common::Config::pathLink,
                        -argv => $self->getVXPN()
                       );
    my @paths = ClearCase::getOutput();
    grep chomp, @paths;
    my $parent = undef;
    while( not @paths )
     {
        $parent = $self->getParent();
        return undef unless( $parent ); # this will never be because the initial task 'main' has at least a path attached, generated during installation
        @paths = @{ $parent->getPath() };
     }
    grep s/^\s*\->\s+(.*)$/$1/, @paths;
    grep s/\.\@\@$//, @paths;
    grep s/\@\@$//, @paths;
    my @result = reverse sort @paths;
    return $self->setPath( \@result );
  }

sub loadParent
  {
    my $self = shift;

    my $baseline = $self->getBaseline();
    return undef unless( $baseline );
    return $self->setParent( $baseline->getTask() );
  }


sub loadCspecPath
  {
    my $self = shift;

    my @paths = @{ $self->getPath() };
    my @cspecPaths = ();
    foreach my $p ( @paths )
      {
	push @cspecPaths, ClearCase::Element->new( -pathname => $p )->getCspecPath();
      }
    return $self->setCspecPath( \@cspecPaths );
  }
1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2010, 2014  by Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com


=head1 SEE ALSO

=cut
