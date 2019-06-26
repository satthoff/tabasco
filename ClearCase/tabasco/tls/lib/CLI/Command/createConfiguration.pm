package CLI::Command::createConfiguration;

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
       '-tasks=s',
       '-releases=s',
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

  my $configName = $self->getOption( 'name' );
  unless( $configName ) {
      Error( [ __PACKAGE__, 'No name for the new configuration has been specified.' ] );
      $self->exitInstance( -1 );
  }
  my $taskNames = $self->getOption( 'tasks' );
  my $releaseNames = $self->getOption( 'releases' );
  if( not $taskNames and not $releaseNames ) {
      Error( [ __PACKAGE__, 'No task name and no release name have been specified.', 'At least one task or one release name is required.' ] );
      $self->exitInstance( -1 );
  }
  $configName =~ s/^$TaBasCo::Common::Config::configurationNamePrefix//;
  $configName = $TaBasCo::Common::Config::configurationNamePrefix . $configName;

  my $environment = TaBasCo::Environment->new();

  if( $environment->getConfiguration( $configName ) ) {
      Error( [ __PACKAGE__, 'A configuration ' . $configName . ' already exists.' ] );
      $self->exitInstance( -1 );
  }

  my @tasks = ();
  my @errors = ();
  my $refTasks = undef;
  if( $taskNames ) {
      my @names = split /,/, $taskNames;
      foreach my $tn ( @names ) {
	  $tn =~ s/^$TaBasCo::Common::Config::taskNamePrefix//;
	  $tn = $TaBasCo::Common::Config::taskNamePrefix . $tn;
	  my $task = $environment->getTask( $tn );
	  if( $task ) {
	      push @tasks, $task;
	  } else {
	      push @errors, $tn;
	  }
      }
      if( @errors ) {
	  Error( [ __PACKAGE__, 'The following tasks do not exist:' ] );
	  foreach my $m( @errors ) {
	      print "\t$m\n";
	  }
	  $self->exitInstance( -1 );
      }
      $refTasks = \@tasks;
  }

  my @releases = ();
  @errors = ();
  my $refReleases = undef;
  if( $releaseNames ) {
      my @names = split /,/, $releaseNames;
      foreach my $rn ( @names ) {
	  my $release = $environment->getRelease( $rn );
	  if( $release ) {
	      push @releases, $release;
	  } else {
	      push @errors, $rn;
	  }
      }
      if( @errors ) {
	  Error( [ __PACKAGE__, 'The following releases do not exist:' ] );
	  foreach my $m( @errors ) {
	      print "\t$m\n";
	  }
	  $self->exitInstance( -1 );
      }
      $refReleases = \@releases;
  }

  Transaction::start( -comment => 'create new release ' );
  my $newConfig = $environment->createConfiguration(
      -name => $configName,
      -tasks => $refTasks,
      -releases => $refReleases
      );
  Transaction::commit();
  Message( [ __PACKAGE__ , "Successfully created new configuration $configName" ] );
} # run

1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2009,2010,2015 Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com

=head1 SEE ALSO

=cut


