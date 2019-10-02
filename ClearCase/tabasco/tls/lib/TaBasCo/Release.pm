package TaBasCo::Release;

use strict;
use Carp;

use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;

   @ISA = qw(  Exporter Data ClearCase::LbType );

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   require Data;

   %DATA = (
       IsFullRelease => { CALCULATE => \&checkFullRelease },
       Task => { CALCULATE => \&loadTask },
       Previous => { CALCULATE => \&loadPrevious },
       ConfigSpec => { CALCULATE => \&loadConfigSpec },
       BaselinedTasks => { CALCULATE => \&loadBaselinedTasks }
       );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'ClearCase::LbType'
      );

} # sub BEGIN()

sub _init {
   my $self = shift;

   return $self->SUPER::_init( -vob => $TaBasCo::Common::Config::myVob, @_ );
} # _init

sub create {
    my $self = shift;
    Debug( [ '', __PACKAGE__ .'::create' ] );

   my ( $task, $comment, @other ) = $self->rearrange(
      [ 'TASK', 'COMMENT' ],
      @_ );

    unless( $task->exists() ) {
	Error( [ __PACKAGE__ . '::create : Task ' . $task->getName() . ' does not exist.' ] );
	return undef;
    }
    unless( $comment ) {
	$comment = __PACKAGE__ . '::create - no purpose specified.';
    }
    $self->SUPER::create( -comment => $comment );
    $self->_registerAsTaskMember( $task );
    return $self;
}

sub _registerAsTaskMember {
    my $self = shift;
    my $task = shift;
    Debug( [ '', __PACKAGE__ .'::_registerAsTaskMember' ] );

    $self->createHyperlinkToObject(
	-hltype => ClearCase::HlType->new( -name => $TaBasCo::Common::Config::myTaskLink, -vob => $self->getVob() ),
	-object => $task
	);
    return $self;
}

sub registerAsNextReleaseOf {
    my $self = shift;
    my $previous = shift;
    Debug( [ '', __PACKAGE__ .'::registerAsNextReleaseOf' ] );

    $self->createHyperlinkFromObject(
	-hltype => ClearCase::HlType->new( -name => $TaBasCo::Common::Config::nextReleaseLink, -vob => $self->getVob() ),
	-object => $previous
	);
    return $self;
}

sub ensureAsFullRelease {
    my $self = shift;
    Debug( [ '', __PACKAGE__ .'::ensureAsFullRelease' ] );

    my $view = $ClearCase::Common::Config::myHost->getCurrentView();
    unless( $view ) {
	Die( [ __PACKAGE__ . '::ensureAsFullRelease', 'We have no current view set.' ] );
    }

    Transaction::start( -comment => 'set required config spec to label a full release ' . $self->getName() );
    $view->setConfigSpec( $self->getTask()->getConfigSpec() );

    Transaction::start( -comment => 'label entire release ' . $self->getName() );
    foreach my $tP ( @{ $self->getTask()->getPaths() } ) {
	my $normalPath = $tP->getNormalizedPath();
	ClearCase::mklabel(
	    -label => $self->getName(),
	    -replace => 1,
	    -recurse => 1,
	    -argv => $normalPath
	    );
    }
    my $fullFlag = ClearCase::Attribute->new(
	-attype => ClearCase::AtType->new( -name => $TaBasCo::Common::Config::fullReleaseFlag, -vob => $self->getVob() ),
	-to     => $self
	);
    $fullFlag->create();
    Transaction::commit(); # commit all label operations
    
    Transaction::rollback(); # reset the config spec
}

sub checkFullRelease {
    my $self = shift;
    Debug( [ '', __PACKAGE__ .'::checkFullRelease' ] );

    ClearCase::describe(
	-localquery => 1,
	-short => 1,
	-aat => $TaBasCo::Common::Config::fullReleaseFlag,
	-argv => $self->getFullName()
	);
    my @results = ClearCase::getOutput();
    grep chomp, @results;
    if( @results ) {
	return $self->setIsFullRelease( 1 );
    }
    return undef;
}

sub loadBaselinedTasks {
    my $self = shift;

    my @result = $self->getToHyperlinkedObjects( ClearCase::HlType->new( -name => $TaBasCo::Common::Config::baselineLink, -vob => $self->getVob() ) );
    my @tasks = ();
    foreach my $t ( @result ) {
	push @tasks, TaBasCo::Task->new( -name => $t );
    }
    return $self->setBaselinedTasks( \@tasks );
}

sub loadPrevious {
    my $self = shift;
    Debug( [ '', __PACKAGE__ .'::loadPrevious' ] );

    my @result = $self->getToHyperlinkedObjects( ClearCase::HlType->new( -name => $TaBasCo::Common::Config::nextReleaseLink, -vob => $self->getVob() ) );
    if( @result ) {
	if( $#result != 0 ) {
	    Die( [ '', "incorrect number ($#result) of next release links $TaBasCo::Common::Config::nextReleaseLink at release " . $self->getFullName(), '' ] );
	}
	# we expect the result to be a TaBasCo::Release
	return $self->setPrevious( TaBasCo::Release->new( -name => $result[0] ) );
    } elsif( $self->getTask()->getBaseline()->getName() ne $self->getName() ) {
	return $self->setPrevious( $self->getTask()->getBaseline() );
    }
    # here we are at the top of a task hierarchy.
    # therefore we do not have any previous releases.
    return undef;
}

sub loadTask {
    my $self = shift;
    Debug( [ '', __PACKAGE__ .'::loadTask' ] );

    my @result = $self->getFromHyperlinkedObjects( ClearCase::HlType->new( -name => $TaBasCo::Common::Config::myTaskLink, -vob => $self->getVob() ) );
    if( $#result != 0 ) {
	Die( [ '', "incorrect number ($#result) of task member links $TaBasCo::Common::Config::myTaskLink at release " . $self->getFullName(), '' ] );
    }
    # we expect the result to be a TaBasCo::Task
    my $task = TaBasCo::Task->new( -name => $result[0] );
    unless( $task->exists() ) {
	Die( [ '', "Hyperlink $TaBasCo::Common::Config::myTaskLink on release " . $self->getFullName() . " does not point to an existing TaBasCo::Task in Vob " . $self->getVob()->getTag(), '' ] );
    }
    
    return $self->setTask( $task );
}

sub loadConfigSpec {
    my $self = shift;
    Debug( [ '', __PACKAGE__ .'::loadConfigSpec' ] );

    my @config_spec = ();

    &TaBasCo::Common::Config::cspecHeader( \@config_spec );

    push @config_spec, '';
    push @config_spec, $TaBasCo::Common::Config::cspecDelimiter;
    push @config_spec, '# BEGIN Release : ' . $self->getName();
    push @config_spec, '# My Task       : ' . $self->getTask()->getName();
    foreach my $np ( @{ $self->getTask()->getPaths() } ) {
	push @config_spec, '# Path : ' . $np->getNormalizedPath();
    }
    push @config_spec, $TaBasCo::Common::Config::cspecDelimiter;

    my $selectedRelease = $self;
    while( $selectedRelease ) {
	foreach my $cp ( @{ $selectedRelease->getTask()->getCspecPaths() } ) {
	    push @config_spec, "element " . $cp . ' ' . $selectedRelease->getName() . " -nocheckout";
	}
	unless( $selectedRelease->getPrevious() ) {
	    # we are at the root task of a task hierarchy
	    my %rootPaths = ();
	    foreach my $np ( @{ $selectedRelease->getTask()->getPaths() } ) {
		my $normPath = $np->getNormalizedPath();
		unless( $normPath eq $np->getVob()->getTag() ) {
		    $normPath = File::Basename::dirname $normPath;
		    $rootPaths{ "$normPath" } = 1;
		}
	    }
	    foreach my $rp ( reverse sort keys %rootPaths ) {
		my $elem = ClearCase::Element->new(
		    -pathname => $rp
		    );
		my $cp = $elem->getCspecPath();
		$cp =~ s/\/\.\.\.//;
		push @config_spec, "element -directory $cp  " . $selectedRelease->getName() . ' -nocheckout';
	    }
	}
	$selectedRelease = $selectedRelease->getPrevious();
    }
 
    push @config_spec, '# END Release   : ' . $self->getName();
    push @config_spec, $TaBasCo::Common::Config::cspecDelimiter;
    push @config_spec, 'element * /main/0 -nocheckout';
    push @config_spec, '';
    
    return $self->setConfigSpec( \@config_spec );
}
1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2006, 2010  Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com


=head1 SEE ALSO

=cut
