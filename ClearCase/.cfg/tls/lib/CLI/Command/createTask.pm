package CLI::Command::createTask;

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
       '-baseline=s',
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

  my $taskName = $self->getOption( 'name' );
  unless( $taskName ) {
      Error( [ 'No task name has been specified.' ] );
      $self->exitInstance( -1 );
  }
  
  my $baselineName = $self->getOption( 'baseline' );
  unless( $baselineName ) {
      Error( [ 'No baseline name has been specified.' ] );
      $self->exitInstance( -1 );
  }
  
  my $comment = '';
  $comment = $self->getOption( 'comment' ) if( $self->getOption( 'comment' ) );

  
  Transaction::start( -comment => 'create new task' . $self->getOption( 'name' ) );
  
  my $baseline = TaBasCo::Release->new( -name => $baselineName );
  unless( $baseline->exists() ) {
      Error( [ "No release exists for the specified baseline $baselineName" ] );
      $self->exitInstance( -1 );
  }
  
  my $newTask = TaBasCo::Task->new( -name => $taskName );
  if( $newTask->exists() ) {
      Error( [ "A task with name $taskName already exists." ] );
      $self->exitInstance( -1 );
  }
  $newTask = $newTask->create( -baseline => $baseline );
  unless( $newTask ) {
      Error( [ '', "Creation of new task $taskName failed."  ] );
      $self->exitInstance( -1 );
  }
  
  Transaction::commit();
  Message( [ '', "Successfully created new task  $taskName"  ] );
  
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


