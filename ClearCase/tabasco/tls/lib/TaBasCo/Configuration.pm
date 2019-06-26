package TaBasCo::Configuration;

use strict;
use Carp;
use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;
   require Data;
   require ClearCase::BrType;

   @ISA = qw(Exporter Data ClearCase::BrType );

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   %DATA = (
       Tasks => { CALCULATE => \&loadTasks },
       Releases => { CALCULATE => \&loadReleases },
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

sub create {
    my $self = shift;

    my ( $tasks, $releases, @other ) = $self->rearrange(
	[ 'TASKS', 'RELEASES' ],
	@_ );

    # we expect all specified tasks and releases to exist

    $self->SUPER::create();

    # register the new config as a known config
    $self->createHyperlinkFromObject(
	-hltype => ClearCase::HlType->new( -name => $TaBasCo::Common::Config::configLink, -vob => $self->getVob() ),
	-object => $self->getVob()->getMyReplica()
	);

    # declare all tasks as member of the config
    if( $tasks ) {
	foreach my $t ( @{ $tasks } ) {
	    $self->createHyperlinkToObject(
		-hltype => ClearCase::HlType->new( -name => $TaBasCo::Common::Config::configTask, -vob => $self->getVob() ),
		-object => $t
		);
	}
    }

    # declare all releases as member of the config
    if( $releases ) {
	foreach my $t ( @{ $releases } ) {
	    $self->createHyperlinkToObject(
		-hltype => ClearCase::HlType->new( -name => $TaBasCo::Common::Config::configRelease, -vob => $self->getVob() ),
		-object => $t
		);
	}
    }
    return $self;
}

sub exists {
    my $self = shift;

    if( $self->SUPER::exists() ) {
	my @result = $self->getToHyperlinkedObjects( ClearCase::HlType->new( -name => $TaBasCo::Common::Config::configLink, -vob => $self->getVob() ) );
	if( $#result > 0 ) {
	    Die( [ __PACKAGE__ , "FATAL ERROR: Incorrect number ($#result) of configuration registration links $TaBasCo::Common::Config::configLink at configuration " . $self->getFullName(), '' ] );
	} elsif( $#result == 0 ) {
	    # we expect the result to be our own replica
	    if( $self->getVob()->getMyReplica()->getFullName() eq $result[0] ) {
		return 1;
	    }
	    Die( [ __PACKAGE__ , "FATAL ERROR: Configuration registration link $TaBasCo::Common::Config::configLink at configuration " . $self->getFullName(),
		 ' is connected to wrong meta object (our own replica expected) ' . $result[0] ] );
	} else {
	    Debug( [ __PACKAGE__ , "A branch type named " . $self->getName() . ' exists, but it is no ' . __PACKAGE__ ] );
	    return 0;
	}
    }
    return 0;
}


sub loadConfigSpec  {
    my $self = shift;

    my @config_spec = ();

    return $self->setConfigSpec( \@config_spec );
}

sub loadTasks  {
    my $self = shift;

    my @tasks = ();
    my @result = $self->getFromHyperlinkedObjects( ClearCase::HlType->new( -name => $TaBasCo::Common::Config::configTask, -vob => $self->getVob() ) );
    foreach my $r ( @result ) {
	push @tasks, TaBasCo::Task->new( -name => $r );
    }
    return $self->setTasks( \@tasks );
}

sub loadReleases  {
    my $self = shift;

    my @releases = ();
    my @result = $self->getFromHyperlinkedObjects( ClearCase::HlType->new( -name => $TaBasCo::Common::Config::configRelease, -vob => $self->getVob() ) );
    foreach my $t ( @result ) {
	push @releases, TaBasCo::Release->new( -name => $t );
    }
    return $self->setReleases( \@releases );
}
1;

__END__

=head1 EXAMPLES

=head1 AUTHOR INFORMATION

 Copyright (C) 2016 Uwe Satthoff

=head1 BUGS

 Address bug reports and comments to:
  satthoff@icloud.com

=head1 SEE ALSO

=cut


