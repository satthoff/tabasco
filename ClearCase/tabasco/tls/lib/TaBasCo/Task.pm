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
       Paths      => { CALCULATE => \&loadPaths },
       CspecPaths => { CALCULATE => \&loadCspecPaths },
       Baseline  => { CALCULATE => \&loadBaseline },
       FloatingRelease => { CALCULATE => \&loadFloatingRelease },
       LastRelease => { CALCULATE => \&loadLastRelease },
       ConfigSpec => { CALCULATE => \&loadConfigSpec }
       );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'ClearCase::BrType'
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

    my $floatingRelease = TaBasCo::Release->new( -name => uc( $self->getName() . $TaBasCo::Common::Config::floatingReleaseExtension ) );
    $floatingRelease->create(
	-task => $self,
	-comment => $comment
	);
    $floatingRelease->_registerAsTaskMember( $self );
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

    if( $self->getName() ne 'main' ) {
	unless( $comment ) {
	    $comment = __PACKAGE__ . '::create - no purpose specified.';
	}
	$self->SUPER::create( -comment => $comment );
    }

    # register the new task as a known task
    $self->createHyperlinkFromObject(
	-hltype => ClearCase::HlType->new( -name => $TaBasCo::Common::Config::taskLink, -vob => $self->getVob() ),
	-object => $self->getVob()->getMyReplica()
	);
    
    # register the provided baseline as the task baseline
    $self->createHyperlinkToObject(
	-hltype => ClearCase::HlType->new( -name => $TaBasCo::Common::Config::baselineLink, -vob => $self->getVob() ),
	-object => $baseline
	);

    # create the task's floating release
    # and register it as the task's first release
    $self->createHyperlinkToObject(
	-hltype => ClearCase::HlType->new( -name => $TaBasCo::Common::Config::firstReleaseLink, -vob => $self->getVob() ),
	-object => $self->_createFloatingRelease()
	);
    
    return $self;
}

sub initializeMainTask {
    my $baselineName = shift;

    my $mainTask = TaBasCo::Task->new( -name => 'main' );
    my $baseline = TaBasCo::Release->new( -name => $baselineName );
    
    # check whether the initialization has already been performed, never execute this subroutine twice!!!!
    my $taskLink = ClearCase::HlType->new(
	-name => $TaBasCo::Common::Config::taskLink,
	-vob => $mainTask->getVob()
	);
    if( $mainTask->getToHyperlinkedObjects( $taskLink ) )  {
	Die( [ __PACKAGE__ . '::initializeMainTask', "The main task has already been initialized." ] );
    }

    $mainTask->create( -baseline => $baseline );
        
    # attach the initial path hyperlinks
    # we expect that TABASCO has been installed in the root Vob of an adminstrative Vob hierarchy or in an ordinary Vob.
    my @elements = ();
    push @elements, $mainTask->allAdminClientsRootElements( $mainTask->getVob() );
    $mainTask->mkPaths( \@elements );
    return $mainTask;
}

sub allAdminClientsRootElements {
    my $self = shift;
    my $vob = shift;

    my @allRootElements = ( $vob->getRootElement() );
    my $clients = $vob->getClientVobs();
    if( $clients ) {
	foreach my $cl ( @$clients ) {
	    push @allRootElements, $self->allAdminClientsRootElements( $cl );
	}
    }
    return @allRootElements;
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

    # lock the new release
    $newRelease->lock();
    
    return $newRelease;
}

sub exists {
    my $self = shift;

    if( $self->SUPER::exists() ) {
	my @result = $self->getToHyperlinkedObjects( ClearCase::HlType->new( -name => $TaBasCo::Common::Config::taskLink, -vob => $self->getVob() ) );
	if( $#result > 0 ) {
	    Die( [ __PACKAGE__ , "FATAL ERROR: Incorrect number ($#result) of task registration links $TaBasCo::Common::Config::taskLink at task " . $self->getFullName(), '' ] );
	} elsif( $#result == 0 ) {
	    # we expect the result to be our own replica
	    if( $self->getVob()->getMyReplica()->getFullName() eq $result[0] ) {
		return 1;
	    }
	    Die( [ __PACKAGE__ , "FATAL ERROR: Task registration link $TaBasCo::Common::Config::taskLink at task " . $self->getFullName(),
		 ' is connected to wrong meta object (our own replica expected) ' . $result[0] ] );
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

sub loadLastRelease {
    my $self = shift;

    my $lastRelease = $self->getFloatingRelease()->getPrevious();
    return $self->setLastRelease if( $lastRelease );
    return undef;
}

sub loadBaseline {
    my $self = shift;

    my @result = $self->getFromHyperlinkedObjects( ClearCase::HlType->new( -name => $TaBasCo::Common::Config::baselineLink, -vob => $self->getVob() ) );
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

    return undef if( $self->getName() eq 'main' ); # Task 'main' has no parent task, it is the root task of all ever existing tasks.
    my $baseline = $self->getBaseline();
    return undef unless( $baseline );
    return $self->setParent( $baseline->getTask() );
}

sub nextReleaseName {
    my $self = shift;
    return uc( $self->getName() ) . '_' . &TaBasCo::Common::Config::gmtTimeString();
}

sub mkPaths {
    my $self = shift;
    my $elements = shift; # we expect a reference to an array of ClearCase::Element objects

    foreach my $elem ( @$elements ) {
	$self->createHyperlinkToObject(
	    -hltype => ClearCase::HlType->new( -name => $TaBasCo::Common::Config::pathLink, -vob => $self->getVob ),
	    -object => $elem
	    );
    }
    return $self->setPaths( $elements );
}

sub loadPaths {
    my $self = shift;

    my @paths = $self->getHyperlinkedFromObjects( ClearCase::HlType->new( -name => $TaBasCo::Common::Config::pathLink, -vob => $self->getVob() ) );
    my $parent = undef;
    if( @paths ) {
	# results must be element paths, so construct them
	# we sort them reverse, what is in general preferrable expected by all ClearCase functions, e.g. within config specs
	my @tmp = @paths;
	@paths = ();
	foreach my $p ( reverse sort @tmp ) {
	    push @paths, ClearCase::Element->new(
		-pathanme => $p
		);
	}
    }
    while( not @paths )
     {
        $parent = $self->getParent();
        return undef unless( $parent );
        @paths = @{ $parent->getPaths() };
     }
    return $self->setPaths( \@paths );
}

sub loadCspecPaths {
    my $self = shift;

    my @paths = @{ $self->getPaths() };
    my @cspecPaths = ();
    foreach my $p ( @paths ) {
	push @cspecPaths, $p->getCspecPath();
    }
    return $self->setCspecPaths( \@cspecPaths );
}

sub loadConfigSpec  {
    my $self = shift;

    my @config_spec = ();
    
    push @config_spec, '';
    push @config_spec, $TaBasCo::Common::Config::cspecDelimiter;
    push @config_spec, '# BEGIN  Task : ' . $self->getName();
    my $pT = 'NONE';
    if( $self->getParent() )
      {
	$pT = $self->getParent()->getName();
      }
    push @config_spec, '# Parent Task : ' . $pT;
    push @config_spec, $TaBasCo::Common::Config::cspecDelimiter;

    if( $self->getName() eq 'main' ) {
	foreach my $p ( @{ $self->getCspecPaths() } ) {
	    push @config_spec, "element $p /" . $self->getName() . "/LATEST";
	}
    } else {
	foreach my $cp ( @{ $self->getCspecPaths() } ) {
	    push @config_spec, "element $cp .../" . $self->getName() . "/LATEST";
	}
	my $baseline = $self->getBaseline();
	push @config_spec, "mkbranch " . $self->getName();
	foreach my $cp (  @{ $self->getCspecPaths() } ) {
	    while( $baseline ) {
		push @config_spec, "element $cp " . $baseline->getName();
		$baseline = $baseline->getPrevious();
	    }
	    $baseline = $self->getBaseline();
	}
	foreach my $cp ( @{ $self->getCspecPaths() } ) {
	    push @config_spec, "element $cp /main/0";
	}
	push @config_spec, "end mkbranch " . $self->getName();
	$baseline = $self->getParent()->getBaseline();
	while( $baseline ) {
	    foreach my $cp ( @{ $baseline->getTask()->getCspecPaths() } ) {
		push @config_spec, "element " . $cp . ' ' . $baseline->getName() . " -nocheckout";
	    }
	    $baseline = $baseline->getPrevious();
	}
    }

    push @config_spec, '# END   Task : ' . $self->getName();
    push @config_spec, $TaBasCo::Common::Config::cspecDelimiter;
    push @config_spec, '';
    grep chomp, @config_spec;

    return $self->setConfigSpec( \@config_spec );
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
