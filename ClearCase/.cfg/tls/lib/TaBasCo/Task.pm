package TaBasCo::Task;

use strict;
use Carp;

use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '09122014_1';
   require Exporter;

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
       Parent    => { CALCULATE => \&loadParent },
       Path      => { CALCULATE => \&loadPath },
       CspecPath => { CALCULATE => \&loadCspecPath },
       Baseline  => { CALCULATE => \&loadBaseline },
       FloatingRelease => { CALCULATE => \&loadFloatingRelease }
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

sub _createFloatingRelease {
    my $self = shift;
    my $comment = shift;

    my $floatingRelease = TaBasCo::Release->new( -name -> uc( $self->getName() . $TaBasCo::Common::Config::floatingReleaseExtension ) );
    $floatingRelease->create(
	-task => $self,
	-comment => $comment
	);
    return $self->setFloatingRelease( $floatingRelease );
}

sub create {
    my $self = shift;

    my ( $baseline, $comment, @other ) = $self->rearrange(
	[ 'BASELINE', 'COMMENT' ],
	@_ );

    unless( $baseline->exists() ) {
	Error( [ __PACKAGE__ . '::create : Baseline ' . $baseline->getName() . ' does not exist.' ] );
	return undef;
    }
    unless( $comment ) {
	$comment = __PACKAGE__ . '::create - no purpose specified.';
    }
    $self->SUPER::create( -comment => $comment );

    # register the new task as a known task
    $self->createHyperlinkFromObject(
	-hltype => ClearCase::HlType->new( -name => $TaBasCo::Common::Config::taskLink ),
	-object => $self->getVob()->getMyReplica()
	);
    
    # register the provided baseline as the task baseline
    $self->createHyperlinkToObject(
	-hltype => ClearCase::HlType->new( -name => $TaBasCo::Common::Config::baselineLink ),
	-object => $baseline
	);

    # create the task's floating release
    # and register it as the task's first release
    $self->createHyperlinkToObject(
	-hltype => ClearCase::HlType->new( -name => $TaBasCo::Common::Config::firstReleaseLink ),
	-object => $self->_createFloatingRelease()
	);

    # TBD - insert code for sub path selection!
    # TBD - insert code for sub path selection!
    
    # my $cspec = $self->_createConfigSpec();
    
    return $self;
}

sub initializeMainTask {
    my $baselineName = shift;

    my $mainTask = TaBasCo::Task->new( -name => 'main' );
    my $baseline = TaBasCo::Release->new( -name => $baselineName );
    unless( $baseline->SUPER::exists() ) {
	Die( [ __PACKAGE__ . '::initializeMainTask', "Label Type $baselineName to be used as baseline for the main task does not exist." ] );
    }
    
    # register the main task as a known task
    $mainTask>createHyperlinkFromObject(
	-hltype => ClearCase::HlType->new( -name => $TaBasCo::Common::Config::taskLink ),
	-object => $self->getVob()->getMyReplica()
	);

    # register the provided baseline as the task baseline
    $mainTask->createHyperlinkToObject(
	-hltype => ClearCase::HlType->new( -name => $TaBasCo::Common::Config::baselineLink ),
	-object => $baseline
	);
    
    # create the main task's floating release
    # and register it as the task's first release
    my $floatingRelease = TaBasCo::Release->new( -name -> uc( $self->getName() . $TaBasCo::Common::Config::floatingReleaseExtension ) );
    $floatingRelease->SUPER::create();
    $mainTask->createHyperlinkToObject(
	-hltype => ClearCase::HlType->new( -name => $TaBasCo::Common::Config::firstReleaseLink ),
	-object => $floatingRelease
	);
    $floatingRelease->_registerAsTaskMember( $mainTask );
    $mainTask->setFloatingRelease( $floatingRelease );

    # attach the initial path hyperlinks
    my @elements = ();
    my @siblingVobs = $mainTask->getVob()->getToHyperlinkedObjects( ClearCase::HlType->new( -name => $ClearCase::Common::Config::adminVobLink ) );
    foreach my $sv ( @siblingVobs ) {
	push @elements, ClearCase::Vob->new( -tag => $sv )->getRootElement();
    }
    push @elements, $mainTask->getVob()->getRootElement();
    
    foreach my $elem ( @elements ) {
	$mainTask->createHyperlinkToObject(
	    -hltype => ClearCase::HlType->new( -name => $TaBasCo::Common::Config::pathLink ),
	    -object => $elem
	    );
    }
}   

sub createNewRelease {
    my $self = shift;
    
    my ( $comment, @other ) = $self->rearrange(
	[ 'COMMENT' ],
	@_ );

    my $newRelease = $self->getFloatingRelease();
    $newRelease->rename(
	-name => $self->nextReleaseName()
	);
    my $floatingRelease = $self->_createFloatingRelease();

    # register the new floating release as the next release of the task
    $floatingRelease->registerAsNextReleaseOf( $newRelease );

    return $newRelease;
}

sub exists {
    my $self = shift;

    if( $self->SUPER::exists() ) {
	my @result = $self->getToHyperlinkedObjects( ClearCase::HlType->new( -name => $TaBasCo::Common::Config::taskLink ) );
	if( $#result > 0 ) {
	    Die( [ __PACKAGE__ , "FATAL ERROR: Incorrect number ($#result) of task registration links $TaBasCo::Common::Config::taskLink at task " . $self->getFullName(), '' ] );
	} elsif( $#result == 0 ) {
	    # we expect the result to be our own replica
	    if( $self->getVob()->getMyReplica()->getFullName() eq $result[0] ) {
		return 1;
	    }
	    Die( [ __PACKAGE__ , "FATAL ERROR: Task registration link $TaBasCo::Common::Config::taskLink at task " . $self->getFullName(),
		 ' is connected to wrong meta object (our own replica expected)' . $result[0] ] );
	} else {
	    Debug( [ __PACKAGE__ , "A branch type named " . $self->getName() . ' exists, but it is no ' . __PACKAGE__ ] );
	    return 0;
	}
    }
    return 0;
}


sub loadFloatingRelease {
    my $self = shift;

    my $floatingRelease = TaBasCo::Release->new( -name -> uc( $self->getName() . $TaBasCo::Common::Config::floatingReleaseExtension ) );
    return $self->setFloatingRelease( $floatingRelease ) if( $floatingRelease->exists() );
    return undef;
}

sub loadBaseline {
    my $self = shift;

    my @result = $self->getFromHyperlinkedObjects( ClearCase::HlType->new( -name => $TaBasCo::Common::Config::baselineLink ) );
    if( $#result != 0 ) {
	Die( [ '', "incorrect number ($#result) of baseline links $TaBasCo::Common::Config::baselineLink at task " . $self->getFullName(), '' ] );
    }
    # we expect the result to be a TaBasCo::Release
    my $baseline = TaBasCo::Release->new( -name => $result[0] );
    unless( $baseline->exists() ) {
	Die( [ '', "Hyperlink $TaBasCo::Common::Config::baselineLink on task " . $self->getFullName() . " does not point to an existing TaBasCo::Release in Vob " . $self->getVob()->getTag(), '' ] );
    }
    
    return $self->setBaseline( $baseline );
}

sub loadParent {
    my $self = shift;

    my $baseline = $self->getBaseline();
    return undef unless( $baseline );
    return $self->setParent( $baseline->getTask() );
}

sub nextReleaseName {
    my $self = shift;
    return uc( $self->getName() ) . '_' . &TaBasCo::Common::Config::gmtTimeString();
}

sub mkPath {
    my $self = shift;
    my $path = shift;
    ClearCase::mkhlink(
	-hltype => $TaBasCo::Common::Config::pathLink,
	-from   => $self->getFullName(),
	-to     => $path . '/.@@'
	);
    $self->setPath( $path );
    return $self;
}

sub loadPath {
    my $self = shift;

    my @paths = $self->getHyperlinkedFromObjects( ClearCase::HlType->new( -name => $TaBasCo::Common::Config::pathLink ) );
    my $parent = undef;
    while( not @paths )
     {
        $parent = $self->getParent();
        return undef unless( $parent );
        @paths = @{ $parent->getPath() };
     }
    grep s/\.\@\@$//, @paths;
    grep s/\@\@$//, @paths;
    my @result = reverse sort @paths;
    return $self->setPath( \@result );
}

sub loadCspecPath {
    my $self = shift;

    my @paths = @{ $self->getPath() };
    my @cspecPaths = ();
    foreach my $p ( @paths ) {
	push @cspecPaths, ClearCase::Element->new( -pathname => $p )->getCspecPath();
    }
    return $self->setCspecPath( \@cspecPaths );
}

sub _createConfigSpec  {
    my $self = shift;

    my $config_spec = &TaBasCo::Common::Config::cspecHeader();

    push @$config_spec, '';
    push @$config_spec, $TaBasCo::Common::Config::cspecDelimiter;
    push @$config_spec, '# BEGIN  Task : ' . $self->getName();
    my $pT = 'NONE';
    if( $self->getParent() )
      {
	$pT = $self->getParent()->getName();
      }
    push @$config_spec, '# Parent Task : ' . $pT;
    push @$config_spec, $TaBasCo::Common::Config::cspecDelimiter;

    my $act = $self;
    my $baseline = $act->getBaseline();
    unless( $baseline )
      {
	foreach my $p ( @{ $act->getCspecPath() } )
	  {
	    push @$config_spec, "element $p /" . $act->getName() . "/LATEST";
	  }
      }
    else
      {
	foreach my $p ( @{ $act->getCspecPath() } )
	  {
	    push @$config_spec, "element $p .../" . $act->getName() . "/LATEST";
	  }
	push @$config_spec, "mkbranch " . $act->getName();
	my @paths = @{ $act->getPath() };
	my @cspecPaths = @{ $act->getCspecPath() };
	while( my $p = shift  @paths and  my $cp = shift @cspecPaths  )
	  {
	    while( $baseline )
	      {
		if( $baseline->pathVisible( $p, $view ) )
		  {
		    push @$config_spec, "element $cp " . $baseline->getName();
		  }
		$baseline = $baseline->getPrevious();
	      }
	    $baseline = $act->getBaseline();
	  }
	$baseline = $act->getBaseline();
	foreach my $p ( @{ $act->getCspecPath() } )
	  {
	    push @$config_spec, "element $p /main/0";
	  }
	push @$config_spec, "end mkbranch " . $act->getName();
	while( $baseline )
	  {
	    foreach my $p ( @{ $baseline->getTask()->getCspecPath() } )
	      {
		push @$config_spec, "element " . $p . ' ' . $baseline->getName() . " -nocheckout";
	      }
	    $baseline = $baseline->getPrevious();
	  }
      }

    push @$config_spec, '# END   Task : ' . $self->getName();
    push @$config_spec, $TaBasCo::Common::Config::cspecDelimiter;
    push @$config_spec, 'element * /main/0 -nocheckout';
    grep chomp, @$config_spec;

    return $config_spec;
}
1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2006, 2010, 2014  by Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com


=head1 SEE ALSO

=cut
