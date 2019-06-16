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

    return $self;
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

sub gmtTimeString {
    my $self = shift;

    my @gmt = gmtime();
    my @month = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    my $year = $gmt[5] + 1900;
    my $timeString = sprintf( "%s.%s.%s-GMT-%d.%d.%d", $gmt[3], $month[ $gmt[4] ], $year, $gmt[2], $gmt[1], $gmt[0]);
    return $timeString;
}

sub nextReleaseName {
    my $self = shift;
    return uc( $self->getName() ) . '_' . $self->gmtTimeString();
}

sub mkPath {
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
