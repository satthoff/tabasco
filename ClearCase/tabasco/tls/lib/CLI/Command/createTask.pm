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
      Error( [ __PACKAGE__ , 'No task name has been specified.' ] );
      $self->exitInstance( -1 );
  }  
  my $comment = '';
  $comment = $self->getOption( 'comment' ) if( $self->getOption( 'comment' ) );

  if( $self->getOption( 'baseline' ) and $self->getOption( 'paths' ) ) {
      Error( [ __PACKAGE__ , 'Options -baseline and -paths are mutually exclusive.' ] );
      $self->exitInstance( -1 );
  } elsif( not $self->getOption( 'baseline' ) and not $self->getOption( 'paths' ) ) {
      Error( [ __PACKAGE__ , 'One of the options -baseline | -paths must be specified.' ] );
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
  } else {
      my $fn = $self->getOption( 'paths' );
      unless( open FD, "$fn" ) {
	  Error( [ __PACKAGE__ , "Cannot read file $fn." ] );
	  $self->exitInstance( -1 );
      };
      Transaction::start( -comment => 'create new task with specified paths' );

      my @pathSpecs = <FD>;
      grep chomp, @pathSpecs;
      close FD;
      grep s/^\s+//, @pathSpecs;
      grep s/\s+$//, @pathSpecs;
      grep s/\/+$//, @pathSpecs;
      my $i = 0;
      my @pathElements = ();
      my @errors = ();
      my @minimizedPaths = ();

      # always add the TaBasCo installation root path
      # to ensure that the TaBasCo tool is included in config specs
      # of tasks and releases
      my $pattern = quotemeta( $TaBasCo::Common::Config::installRoot );
      unless( grep m/^${pattern}$/, @pathSpecs ) {
	  push @pathSpecs, $TaBasCo::Common::Config::installRoot;
      }

      foreach my $p ( @pathSpecs ) {
	  $i++;
	  if( not -e "$p" ) {
	      push @errors, "Path $p specified in line $i is not accessible.";
	  } elsif( not -d "$p" ) {
	      push @errors, "Path $p specified in line $i is not a directory.";
	  }
      }
      if( @errors ) {
	  Error( [ __PACKAGE__ , 'Errors in file ' . $self->getOption( 'paths' ) . ' :' ] );
	  foreach my $l ( @errors ) {
	      Error( [ __PACKAGE__ , $l ] );
	  }
	  $self->exitInstance( -1 );
      }
      
      # minimze paths
      my @sortedPaths = sort @pathSpecs;
      my @minimizedPaths = @sortedPaths;
      my @tmp = ();
      while( my $checkPath = shift @sortedPaths ) {
	  my $pattern = quotemeta( $checkPath );
	  foreach my $p ( sort @minimizedPaths ) {
	      if( "$p" eq "$checkPath" or $p !~ m/^$pattern\// ) {
		  push @tmp, $p;
	      }
	  }
	  @minimizedPaths = @tmp;
	  @tmp = ();
      }

      # generate path elements
      foreach my $p ( @minimizedPaths ) {
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
  }
  Transaction::commit();
  Message( [ __PACKAGE__ , "Successfully created new task  $taskName"  ] );
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


