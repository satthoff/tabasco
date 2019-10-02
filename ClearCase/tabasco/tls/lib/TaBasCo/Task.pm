package TaBasCo::Task;

use strict;
use Carp;
use File::Basename;

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
    Debug( [ '', __PACKAGE__ .'::_createFloatingRelease' ] );

    my $floatingRelease = TaBasCo::Release->new( -name => uc( $self->getName() . $TaBasCo::Common::Config::floatingReleaseExtension ) );
    $floatingRelease->create(
	-task => $self,
	-comment => $comment
	);
    return $self->setFloatingRelease( $floatingRelease );
}

sub create {
    my $self = shift;
    Debug( [ '', __PACKAGE__ .'::create' ] );

    my ( $baseline, $comment, $restrictpath, $elements, @other ) = $self->rearrange(
	[ 'BASELINE', 'COMMENT', 'RESTRICTPATH', 'ELEMENTS' ],
	@_ );

    if( $self->getName() eq 'main' ) {
	Error( [ __PACKAGE__ . '::create : The predefined branch type "main" cannot become a task.' ] );
	return undef;
    }
    
    unless( $comment ) {
	$comment = __PACKAGE__ . '::create - no purpose specified.';
    }
    $self->SUPER::create( -comment => $comment );

    if( $baseline ) {
	unless( $baseline->exists() ) {
	    Error( [ __PACKAGE__ . '::create : Baseline ' . $baseline->getName() . ' does not exist.' ] );
	    return undef;
	}
    } elsif( $elements ) {
	# the new task is NOT based on an already existing task release.
	# we create the new baseline as a release of the new task
	$baseline = TaBasCo::Release->new( -name => uc( $self->getName() . '_baseline' ) );
	$baseline->create(
	    -task => $self,
	    -comment => $comment
	    );

	# label all specified elements recursively with the new baseline label
	# and mark it as a full release
	foreach my $tP ( @$elements ) {
	    my $normalPath = $tP->getNormalizedPath();
	    ClearCase::mklabel(
		-label => $baseline->getName(),
		-replace => 1,
		-recurse => 1,
		-argv => $normalPath
		);
	    unless( $normalPath eq $tP->getVob()->getTag() ) {
		$normalPath = File::Basename::dirname $normalPath;
		ClearCase::mklabel(
		    -label => $baseline->getName(),
		    -replace => 1,
		    -argv => $normalPath
		    );
	    }
	}
	my $fullFlag = ClearCase::Attribute->new(
	    -attype => ClearCase::AtType->new( -name => $TaBasCo::Common::Config::fullReleaseFlag, -vob => $self->getVob() ),
	    -to     => $baseline
	    );
	$fullFlag->create();

	# finally attach all elements as paths of the new task
	$self->mkPaths( $elements );
    } else {
	Error( [ __PACKAGE__ . '::create : No list of elements nor a baseline have been specified.' ] );
	return undef;
    }
    
    # register the new task as a known task
    $self->createHyperlinkFromObject(
	-hltype => ClearCase::HlType->new( -name => $TaBasCo::Common::Config::taskLink, -vob => $self->getVob() ),
	-object => $self->getVob()->getMyReplica()
	);
    
    # register the provided or newly created baseline as the task baseline
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

    if( $restrictpath and not $elements and $self->getParent() ) {
	# load the user interface
	my $ui = TaBasCo::UI->new();

	$ui->okMessage( "Path restriction is requested. We will step through all paths of the parent task." );

	# we have to set the config spec of the task's baseline
	# otherwise the directory selection might not work
	Transaction::start( -comment => "set correct config spec for directory selection" );
	my $currentView = $ClearCase::Common::Config::myHost->getCurrentView();
	$currentView->setConfigSpec( $self->getBaseline()->getConfigSpec() );

	# start an inner transaction to be able to re-set the config spec by
	# releasing the parent transaction
	Transaction::start( -comment => "inner transaction for path restriction" );

	# get my parent's paths
	my $parentPaths = $self->getParent()->getPaths();
	my %pathCollection = ();
	if( $parentPaths ) {
	    foreach my $parentPathElement ( @$parentPaths ) {
		my $newPath = '';
		my $parentPath = $parentPathElement->getNormalizedPath();
		while( $newPath = $ui->selectDirectory( -question  => 'Select a directory to be used for your new task. Cancel to finish. Select the "." to add this path:', -directory => $parentPath ) ) {
		    $parentPath =~ s/\\/\//g;
		    $newPath =~ s/\\/\//g;
		    my $i = index( $newPath, $parentPath);
		    if( ($i == 0) and (length( $newPath ) >= length( $parentPath )) ) {
			my $ccElem = ClearCase::Element->new( -pathname => $newPath );
			$pathCollection{ $newPath } = $ccElem if( $ccElem ); # add the path only if it is a CC element
			$ui->okMessage( "Added path $newPath to new task." );
		    } else {
			$ui->okMessage( "The path must be a subpath of the parent path." );
		    }
		}
	    }
	    my @allPaths = keys %pathCollection;
	    if( @allPaths ) {
		# always add the TaBasCo installation root path
		# to ensure that the TaBasCo tool is included in config specs
		# of tasks and releases
		my $pattern = quotemeta( "$TaBasCo::Common::Config::installRoot" );
		unless( grep m/^${pattern}$/, @allPaths ) {
		    $pathCollection{ "$TaBasCo::Common::Config::installRoot" } = ClearCase::Element->new( -pathname => $TaBasCo::Common::Config::installRoot );
		}
		my @values = values %pathCollection;
		Debug( [ 'CHECK PATHS' ] );
		for my $p ( keys %pathCollection ) {
		    Debug( [ ">$p<" ] );
		}
		$self->mkPaths( \@values );
	    }
	    Transaction::commit();  # commit all path actions done
	} else {
	    Transaction::release(); # release the inner transaction
	}
	Transaction::rollback(); # reset the config spec
    }

    return $self;
}

sub allAdminClientsRootElements {
    my $self = shift;
    my $vob = shift;
    Debug( [ '', __PACKAGE__ .'::allAdminClientsRootElements' ] );

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
    Debug( [ '', __PACKAGE__ .'::createNewRelease' ] );
    
    my ( $comment, $fullrelease, @other ) = $self->rearrange(
	[ 'COMMENT', 'FULLRELEASE' ],
	@_ );

    my $newRelease = $self->getFloatingRelease();
    if( $fullrelease ) {
	$newRelease->ensureAsFullRelease();
    }
    $newRelease->rename( $self->nextReleaseName() );
    my $floatingRelease = $self->_createFloatingRelease();

    # register the new floating release as the next release of the task
    $floatingRelease->registerAsNextReleaseOf( $newRelease );
    
    return $newRelease;
}

sub printStruct {
    my $self = shift;
    my $indent = shift;

    unless( $indent ) {
	$indent = '';
    }

    print $indent . "===============================================\n";
    print $indent . '|Task : ' . $self->getName() . "\n";
    foreach my $np ( @{ $self->getPaths() } ) {
	print $indent . '|Path : ' . $np->getNormalizedPath() . "\n";
    }
    my $rel = $self->getLastRelease();
    while( $rel ) {
	last if( $rel->getTask()->getName() ne $self->getName() );
	my $relKind = 'delta';
	if( $rel->getIsFullRelease() ) {
	    $relKind = 'full';
	}
	print $indent . '|Release : ' . $rel->getName() . " ($relKind)\n";
	my @tasks = @{ $rel->getBaselinedTasks() };
	foreach my $t( @tasks ) {
            next if( $self->getName() eq $t->getName() );
	    $t->printStruct( $indent . '|---> ' );
	}
	$rel = $rel->getPrevious();
    }
    print $indent . "===============================================\n";
}

sub printMe {
    my $self = shift;
    my $long = shift;
    Debug( [ '', __PACKAGE__ .'::printMe' ] );

    print $self->getName() . "\n";
    if( $long ) {
	foreach my $line ( @{ $self->getConfigSpec() } ) {
	    print "\t$line\n";
	}
	print "\tReleases:\n";
	my $rel = $self->getLastRelease();
	while( $rel ) {
	    last if( $rel->getTask()->getName() ne $self->getName() );
	    my $relKind = 'delta';
	    if( $rel->getIsFullRelease() ) {
		$relKind = 'full';
	    }
	    print "\t\t" . $rel->getName() . " ($relKind)\n";
	    $rel = $rel->getPrevious();
	}
    }
}

sub loadFloatingRelease {
    my $self = shift;
    Debug( [ '', __PACKAGE__ .'::loadFloatingRelease' ] );

    my $floatingRelease = TaBasCo::Release->new( -name => uc( $self->getName() . $TaBasCo::Common::Config::floatingReleaseExtension ) );
    return $self->setFloatingRelease( $floatingRelease ) if( $floatingRelease->exists() );
    return undef;
}

sub loadLastRelease {
    my $self = shift;
    Debug( [ '', __PACKAGE__ .'::loadLastRelease' ] );

    my $lastRelease = $self->getFloatingRelease()->getPrevious();
    return $self->setLastRelease( $lastRelease ) if( $lastRelease );
    return undef;
}

sub loadBaseline {
    my $self = shift;
    Debug( [ '', __PACKAGE__ .'::loadBaseline' ] );

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
    Debug( [ '', __PACKAGE__ .'::loadParent' ] );

    my $baseline = $self->getBaseline();
    return undef unless( $baseline );
    return undef if( $baseline->getTask()->getName() eq $self->getName() );
    return $self->setParent( $baseline->getTask() );
}

sub nextReleaseName {
    my $self = shift;
    Debug( [ '', __PACKAGE__ .'::nextReleaseName' ] );
    return uc( $self->getName() ) . '_' . &TaBasCo::Common::Config::gmtTimeString();
}

sub mkPaths {
    my $self = shift;
    my $elements = shift; # we expect a reference to an array of ClearCase::Element objects
    Debug( [ '', __PACKAGE__ .'::mkPaths' ] );

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
    Debug( [ '', __PACKAGE__ .'::loadPaths' ] );

    my @paths = $self->getFromHyperlinkedObjects( ClearCase::HlType->new( -name => $TaBasCo::Common::Config::pathLink, -vob => $self->getVob() ) );
    my $parent = undef;
    if( @paths ) {
	# results must be element paths, so construct them
	# we sort them reverse, what is in general preferrable expected by all ClearCase functions, e.g. within config specs
	my @tmp = @paths;
	@paths = ();
	foreach my $p ( reverse sort @tmp ) {
	    push @paths, ClearCase::Element->new(
		-pathname => $p
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
    Debug( [ '', __PACKAGE__ .'::loadCspecPaths' ] );

    my @paths = @{ $self->getPaths() };
    my @cspecPaths = ();
    foreach my $p ( @paths ) {
	push @cspecPaths, $p->getCspecPath();
    }
    return $self->setCspecPaths( \@cspecPaths );
}

sub loadConfigSpec  {
    my $self = shift;
    Debug( [ '', __PACKAGE__ .'::loadConfigSpec' ] );

    my @config_spec = ();

    push @config_spec, 'element * CHECKEDOUT';
    &TaBasCo::Common::Config::cspecHeader( \@config_spec );

    push @config_spec, '';
    push @config_spec, $TaBasCo::Common::Config::cspecDelimiter;
    push @config_spec, '# BEGIN  Task : ' . $self->getName();
    push @config_spec, '# Baseline : ' . $self->getBaseline()->getName();
    my $pT = 'NONE';
    if( $self->getParent() )
      {
	$pT = $self->getParent()->getName();
      }
    push @config_spec, '# Parent Task : ' . $pT;
    foreach my $np ( @{ $self->getPaths() } ) {
	push @config_spec, '# Path : ' . $np->getNormalizedPath();
    }
    push @config_spec, $TaBasCo::Common::Config::cspecDelimiter;

    foreach my $cp ( @{ $self->getCspecPaths() } ) {
	push @config_spec, "element $cp .../" . $self->getName() . "/LATEST";
    }
    my $selectedRelease = $self->getBaseline();
    push @config_spec, "mkbranch " . $self->getName();
    while( $selectedRelease ) {
	foreach my $cp (  @{ $self->getCspecPaths() } ) {
	    push @config_spec, "element $cp " . $selectedRelease->getName();
	}
	$selectedRelease = $selectedRelease->getPrevious();
    }
    foreach my $cp ( @{ $self->getCspecPaths() } ) {
	push @config_spec, "element $cp /main/0";
    }
    push @config_spec, "end mkbranch " . $self->getName();

    push @config_spec, grep( !m/^#/, @{ $self->getBaseline()->getConfigSpec() } );
    
    push @config_spec, '';
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

 Copyright (C) 2006, 2010, 2014, 2019  by Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com


=head1 SEE ALSO

=cut
