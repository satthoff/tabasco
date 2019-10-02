package CLI::Command::listTasks;

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
       '-long',
       '-struct'
       );
   
   return;
} # initInstance


sub run {
  my $self = shift;

  my @tasks = ();
  my $environment = TaBasCo::Environment->new();
  if( $self->getOption( 'struct' ) ) {
      my %tmp = %{ $environment->getAllTasks() };
      my @tasks = values %tmp;
      my @rootTasks = ();
      foreach my $t ( @tasks ) {
	  push @rootTasks, $t unless( $t->getParent() );
      }
      foreach my $rt ( @rootTasks ) {
	  $rt->printStruct( ' ' );
      }
  } else {
      if( @ARGV ) {
	  foreach my $taskName ( @ARGV ) {
	      if( $environment->getTask( $taskName ) ) {
		  push @tasks, $environment->getTask( $taskName );
	      } else {
		  Error( [ __PACKAGE__, "A task with name $taskName does not exist." ] );
	      }
	  }
	  return unless( @tasks );
	  print "\n\n";
      } else {
	  if( $environment->getAllTasks() ) {
	      my %tmp = %{ $environment->getAllTasks() };
	      foreach ( keys %tmp ) {
		  push @tasks, $tmp{ $_ };
	      }
	  }
      }
      foreach my $t ( @tasks ) {
	  $t->printMe( $self->getOption( 'long' ) );
	  print "\n\n";
      }
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


