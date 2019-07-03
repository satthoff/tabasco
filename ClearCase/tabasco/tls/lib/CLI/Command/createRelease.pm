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
       '-task=s',
       '-comment=s',
       '-full'
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
      Error( [ __PACKAGE__ , "No TaBasCo::Task exists with name $taskName" ] );
      $self->exitInstance( -1 );
  }
  $taskName = $task->getName();
  
  my $comment = '';
  $comment = $self->getOption( 'comment' ) if( $self->getOption( 'comment' ) );

  
  Transaction::start( -comment => 'create new release ' );

  my $newRelease = $task->createNewRelease(
      -comment => $comment,
      -fullrelease => $self->getOption( 'full' )
      );

  unless( $newRelease ) {
      Error( [ __PACKAGE__ , "Creation of new release failed."  ] );
      $self->exitInstance( -1 );
  }
  my $releaseName = $newRelease->getName();
 
  Transaction::commit();
  Message( [ __PACKAGE__ , "Successfully created new release $releaseName in task $taskName" ] );
  
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


