package CLI::Command::listConfigurations;

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
       '-long'
       );
   
   return;
} # initInstance


sub run {
  my $self = shift;

  my @configs = ();
  my $environment = TaBasCo::Environment->new();
  if( @ARGV ) {
      foreach my $configName ( @ARGV ) {
	  if( $environment->getConfiguration( $configName ) ) {
	      push @configs, $environment->getConfiguration( $configName );
	  } else {
	      Error( [ __PACKAGE__, "A configuration with name $configName does not exist." ] );
	  }
      }
      return unless( @configs );
  } else {
      if( $environment->getAllConfigurations() ) {
          my %tmp = %{ $environment->getAllConfigurations() };
          foreach ( keys %tmp ) {
              push @configs, $tmp{ $_ };
          }
      }
  }
  foreach my $t ( @configs ) {
      $t->printMe( $self->getOption( 'long' ) );
      print "\n";
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


