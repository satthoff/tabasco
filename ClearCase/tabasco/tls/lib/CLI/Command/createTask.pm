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
       '-comment=s',
       '-paths=s',
       '-restrictpaths'
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
  my $comment = '';
  $comment = $self->getOption( 'comment' ) if( $self->getOption( 'comment' ) );

  if( $self->getOption( 'baseline' ) and $self->getOption( 'paths' ) ) {
      Error( [ 'Options -baseline and -paths are mutually exclusive.' ] );
      $self->exitInstance( -1 );
  }
  
  my $newTask = TaBasCo::Task->new( -name => $taskName );
  $taskName = $newTask->getFullName();
  if( $newTask->exists() ) {
      Error( [ __PACKAGE__ , "A task with name $taskName already exists." ] );
      $self->exitInstance( -1 );
  }

  if( $self->getOption( 'baseline' ) ) {
      my $baselineName = $self->getOption( 'baseline' );
      unless( $baselineName ) {
	  Error( [ 'No baseline name has been specified.' ] );
	  $self->exitInstance( -1 );
      }
      Transaction::start( -comment => 'create new task with specified baseline' );
  
      my $baseline = TaBasCo::Release->new( -name => $baselineName );
      # existence of the release will be checked during task creation
  
      $newTask = $newTask->create(
	  -baseline => $baseline,
	  -comment => $comment,
	  -restrictpath => $self->getOption( 'restrictpaths' )
	  );
      unless( $newTask ) {
	  Error( [ __PACKAGE__ , "Creation of new task $taskName failed."  ] );
	  $self->exitInstance( -1 );
      }
  
      Transaction::commit();
      Message( [ __PACKAGE__ , "Successfully created new task  $taskName"  ] );
  } else {
      open FD, '"' . $self->getOption( 'paths' ) . '"' || {
	  Error( [ 'File ' . $self->getOption( 'paths' ) . ' specified with option -paths does not exist or is not readable.' ] );
	  $self->exitInstance( -1 );
      }
      Transaction::start( -comment => 'create new task with specified paths' );

      my @pathSpecs = <FD>;
      grep chomp, @pathSpecs;
      close FD;
      my $i = 0;
      my @pathElements = ();
      foreach my $p ( @pathSpecs ) {
	  $i++;
	  if( not -e "$p" ) {
	      Error( [ "Path $p specified in line $i is not accessible." ] );
	      $self->exitInstance( -1 );
	  }
	  push @pathElements, ClearCase::Element->new(
		-pathname => $p
		);
      }
      $newTask = $newTask->create(
	  -elements => \@pathElements,
	  -comment => $comment
	  );
      unless( $newTask ) {
	  Error( [ __PACKAGE__ , "Creation of new task $taskName failed."  ] );
	  $self->exitInstance( -1 );
      }
      Transaction::commit();
      Message( [ __PACKAGE__ , "Successfully created new task  $taskName"  ] );
  }
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


