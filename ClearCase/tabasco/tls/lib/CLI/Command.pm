package CLI::Command;

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

   @ISA = qw(Exporter);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

} # sub BEGIN()


my $theInstance = undef;

sub new()
{
   carp "Error: there is a existing Instance of __PACKAGE__"
     if defined $theInstance;

   my $proto = shift;
   my $class = ref( $proto ) || $proto;
   $theInstance = {};

   bless( $theInstance, $class );
   return $theInstance;
} # new ()

my $UI;
sub setUI {
   my $self = shift;
   $UI = shift;
}

sub getUI {
   my $self = shift;
   return $UI;
}

sub exitInstance( $ )
{
   my ( $self, $rc ) = @_;

   while( Transaction::getTransaction() )
   {
      Transaction::rollback();
   };

   Progress("end of application");
   exit( $rc );
}

sub getInstance {
  return $theInstance;
}

my $user;
sub getUser {
 my $self = shift;
   return $user if defined $user;
   return $user = CLI::User->_new();
}

sub getOption( $ )
{
   my ( $self, $option ) = @_;
   return $self->{'COMMAND_OPTION'}->{"$option"};
}

sub setOption( $ )
{
   my ( $self, $option, $value ) = @_;
   $self->{'COMMAND_OPTION'}->{"$option"} = $value;
}


sub initInstance( $ )
{
   my ( $self, @allowed_options ) = @_;
   my %options;

   # parse the Options
   GetOptions(
      \%options,
      'version',
      'help',
      'verbosity=s',
      @allowed_options )      # parse the options
      or exit -1;

   $self->{'COMMAND_OPTION'} = \%options;


   if( defined $self->getOption('help') )
   {
     # print help and exit
     $self->help();
     exit;
   }


   ###
   ### SET VERBOSITY
   ###
   Progress( "Setting Verbosity\n");
   my $verbosity =
      defined $self->getOption( 'verbosity' )
         ? $self->getOption( 'verbosity' )
         : defined $ENV{'SDEV_VERBOSITY'}
            ? $ENV{'SDEV_VERBOSITY'}
            : 'DEFAULT';

   $ENV{'SDEV_VERBOSITY'}    = $verbosity;
   $ENV{'SDEV_VERBOSITY_NR'} = Log::setVerbosity( $verbosity );


   require CLI::UI;
   $self->setUI( CLI::UI->new() );

}

sub help
  {
      my $self = shift;

      my $name = ref( $self );
      $name  =~ s/.*::(\S+)$/$1/;
      print $CLI::Config::COMMAND{ $name }->{ 'helptext' } . "\n";
  }

sub printEnvironmentHeader
  {
    my $self = shift;

    my $line = '-' x (18 + length( $CLI::Config::Version ) + length( $CLI::Config::COPYRIGHT ) );
    print "\n$line\n";
    print "Version     : " . $CLI::Config::VERSION . " by $CLI::Config::COPYRIGHT\n";
    print "$line\n\n";
  }

sub main {
   my ( $self ) = shift;
   my $rc;

   eval {
      local $SIG{'INT'} = sub {
         $SIG{'INT'} = 'IGNORE';
         Message( [ 'CAUGHT SIGINT', '....try to rollback actual transaction, please wait.' ] );
         CLI::Command::getInstance()->exitInstance(-1);
         };

      # initialize the Command.
      $self->initInstance();

      # Execute the Command Main Loop
      $rc = $self->run();

   };
   if ( $@ ) {
      Message( [ $@ ] );
      $rc = -1;
   }

   # Make a clean end
   $self->exitInstance( $rc );
} # main

1;

__END__

=head1 EXAMPLES

=head1 AUTHOR INFORMATION

 Copyright (C) 2009 Uwe Satthoff

=head1 BUGS

 Address bug reports and comments to:
  satthoff@icloud.com

=head1 SEE ALSO

=cut


