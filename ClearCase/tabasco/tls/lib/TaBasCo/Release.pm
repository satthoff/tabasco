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
	    Task => { CALCULATE => \&loadTask },
	    Name => { CALCULATE => \&loadName },
	    Previous => { CALCULATE => \&loadPrevious }
	   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => "ClearCase::Version"
      );

} # sub BEGIN()

sub _init {
   my $self = shift;

   return $self->SUPER::_init( -vob => $TaBasCo::Common::Config::myVob, @_ );
} # _init

sub create {
    my $self = shift;

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

sub _registerAsTaskMember  {
    my $self = shift;
    my $task = shift;

    $self->createHyperlinkToObject(
	-hltype => ClearCase::HlType->new( -name => $TaBasCo::Common::Config::myTaskLink ),
	-object => $task
	);
    return $self;
}

sub registerAsNextReleaseOf {
    my $self = shift;
    my $previous = shift;

    $self->createHyperlinkToObject(
	-hltype => ClearCase::HlType->new( -name => $TaBasCo::Common::Config::nextReleaseLink ),
	-object => $previous
	);
    return $self;
}

sub ensureAsFullRelease {
    my $self = shift;

}

sub loadPrevious {
    my $self = shift;

    my @result = $self->getToHyperlinkedObjects( ClearCase::HlType->new( -name => $TaBasCo::Common::Config::nextReleaseLink ) );
    return undef unless( @result );
    if( $#result != 0 ) {
	Die( [ '', "incorrect number ($#result) of next release links $TaBasCo::Common::Config::nextReleaseLink at release " . $self->getFullName(), '' ] );
    }
    # we expect the result to be a TaBasCo::Release
    my $release = TaBasCo::Release->new( -name => $result[0] );
    unless( $release->exists() ) {
	Die( [ '', "Hyperlink $TaBasCo::Common::Config::nextReleaseLink on release " . $self->getFullName() . " does not point from an existing TaBasCo::Release in Vob " . $self->getVob()->getTag(), '' ] );
    }

    return $self->setPrevious( $release );
}

sub loadTask {
    my $self = shift;

    my @result = $self->getFromHyperlinkedObjects( ClearCase::HlType->new( -name => $TaBasCo::Common::Config::myTaskLink ) );
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

sub createConfigSpec  {
    my $self = shift;

    my $config_spec = &TaBasCo::Common::Config::cspecHeader();

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
