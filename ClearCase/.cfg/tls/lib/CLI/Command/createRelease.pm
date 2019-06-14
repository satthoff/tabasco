package CLI::Command::createRelease;

use strict;
use Carp;
use CLI;
use Log;
use TaBasCo;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
   $VERSION = '0.09';
   require Exporter;

   @ISA = qw(Exporter CLI::Command);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

} # sub BEGIN()

sub initInstance {
   my ( $self ) = @_;

   # first initialize the base classes
   $self->SUPER::initInstance(
       '-name=s',
       '-task=s',
       '-comment=s'
       );
   
   if ( $#ARGV >= 0 ) {
      Error( [ '', "superfluous arguments \"@ARGV\"" ] );
      $self->help();
      $self->exitInstance(-1);
   }

   return;
} # initInstance


sub run {
  my $self = shift;

  my $taskName = $self->getOption( 'task' );
  unless( $taskName ) {
      Error( [ 'No task name has been specified.' ] );
      $self->exitInstance( -1 );
  }

  my $task = TaBasCo::Task->new( -name => $taskName );
  unless( $task->exists() ) {
      Error( [ "No TaBasCo::Task exists for the specified task name $taskName" ] );
      $self->exitInstance( -1 );
  }
  
  my $releaseName = $self->getOption( 'name' );
  unless( $releaseName ) {
      $releaseName = $task->nextReleaseName();
      Progress( [ 'No release name has been specified.', "Default name $releaseName will be used." ] );
  }
  
  my $comment = '';
  $comment = $self->getOption( 'comment' ) if( $self->getOption( 'comment' ) );

  
  Transaction::start( -comment => 'create new release ' . $releaseName );
  
  my $newRelease = TaBasCo::Release->new( -name => $releaseName );
  if( $newRelease->exists() ) {
      Error( [ "TaBasCo::Release $releaseName already exists." ] );
      $self->exitInstance( -1 );
  }
 
  $newRelease = $newRelease->create( -task => $task, -comment => $comment );
  unless( $newRelease ) {
      Error( [ "Creation of new release $releaseName failed."  ] );
      $self->exitInstance( -1 );
  }
  
  Transaction::commit();
  Message( [ '', "Successfully created new release $releaseName in task $taskName" ] );
  
} # run

1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2009,2010,2012 Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com

=head1 SEE ALSO

=cut


