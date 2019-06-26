package CLI::Command::useConfiguration;

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
       '-configuration=s',
       '-view=s'
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

  my $configName = $self->getOption( 'configuration' );
  unless( $configName ) {
      Error( [ __PACKAGE__, 'No configuration has been specified.' ] );
      $self->exitInstance( -1 );
  }
  my $viewName = $self->getOption( 'view' );
  unless( $viewName ) {
      Error( [ __PACKAGE__, 'No view has been specified.' ] );
      $self->exitInstance( -1 );
  }

  my $environment = TaBasCo::Environment->new();
  my $config = $environment->getConfiguration( $configName );
  unless( $config ) {
      Error( [ __PACKAGE__, "A configuration $configName does not exist." ] );
      $self->exitInstance( -1 );
  }

  my $view = ClearCase::View->new( $viewName );
  my @cspec = $view->getConfigSpec(); # check the view existence, the program dies if the view does not exist

  $view->setConfigSpec( $config->getConfigSpec() );

  Message( [ __PACKAGE__ , "Successfully set config spec of configuration $configName in view $viewName" ] );
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


