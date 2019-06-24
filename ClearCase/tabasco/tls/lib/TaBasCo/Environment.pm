package TaBasCo::Environment;

use strict;
use Carp;
use Getopt::Long;


use Log;
use CLI::User;
use CLI::Config;
use CLI;
use Transaction;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
   $VERSION = '0.01';
   require Exporter;

   @ISA = qw(Exporter );

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   require Data;

   %DATA = (
       AllTasks => { CALCULATE => \&loadAllTasks }
       );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => undef
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

    my $db = $TaBasCo::Common::Config::myVob->getMyReplica();
    my @taskObjects = $db->getFromHyperlinkedObjects(
	ClearCase::HlType( -name => $TaBasCo::Common::Config::taskLink, -vob => $TaBasCo::Common::Config::myVob )
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

    my %tt = %{ $self->getAllTasks() };
    return $tt{ $name } if( defined $tt{ $name } );
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


