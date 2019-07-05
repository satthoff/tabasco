package TaBasCo::Environment;

use strict;
use Carp;
use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;
   require Data;

   @ISA = qw(Exporter Data);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   %DATA = (
       Releases => undef,
       AllTasks => { CALCULATE => \&loadAllTasks }
       );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Data'
      );
} # sub BEGIN()


my $theInstance = undef;

sub new() {
   carp "Error: there is a existing Instance of __PACKAGE__"
     if defined $theInstance;

   my $proto = shift;
   my $class = ref( $proto ) || $proto;
   $theInstance = {};

   bless( $theInstance, $class );
   return $theInstance;
} # new ()

sub loadAllTasks {
    my $self = shift;
    Debug( [ '', __PACKAGE__ .'::loadAllTasks' ] );

    my $db = $TaBasCo::Common::Config::myVob->getMyReplica();
    my @taskObjects = $db->getFromHyperlinkedObjects(
	ClearCase::HlType->new( -name => $TaBasCo::Common::Config::taskLink, -vob => $TaBasCo::Common::Config::myVob )
	);
    my %tasks = ();
    foreach my $to ( @taskObjects ) {
	my $t = TaBasCo::Task->new( -name => $to );
	$tasks{ $t->getName() } = $t;
    }
    return $self->setAllTasks( \%tasks );
}

sub getTask {
    my $self = shift;
    my $name = shift;
    Debug( [ '', __PACKAGE__ .'::getTask' ] );

    my %tt = %{ $self->getAllTasks() };
    return $tt{ $name } if( defined $tt{ $name } );
    return undef;
}

sub getRelease  {
    my $self = shift;
    my $name = shift;
    Debug( [ '', __PACKAGE__ .'::getRelease' ] );

    my %releases =();
    if( $self->getReleases() ) {
	%releases = %{ $self->getReleases() };
    }
    return $releases{ $name } if( defined $releases{ $name } );
    my $requestedRelease = TaBasCo::Release->new( -name => $name );
    if( $requestedRelease->exists() ) {
	$releases{ $name } = $requestedRelease;
	$self->setReleases( \%releases );
	return $requestedRelease;
    }
    return undef;
}

1;

__END__

=head1 EXAMPLES

=head1 AUTHOR INFORMATION

 Copyright (C) 2015 Uwe Satthoff

=head1 BUGS

 Address bug reports and comments to:
  satthoff@icloud.com

=head1 SEE ALSO

=cut


