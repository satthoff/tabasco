#!/opt/rational/clearcase/bin/Perl
#############################################################################
use strict;

require 5.6.1;

my $script_name     = "tabasco.pl";


my @INCL_LIB;

use vars qw( $installPath );

BEGIN {
   use File::Basename;
   use Cwd;
   my $base = dirname ( Cwd::abs_path( dirname $0 ) );
    if ( defined $ENV{OS} )
      {
	  $base =~ s/\//\\/g;
	  push @INCL_LIB, ( "$base", "$base\\lib" );
      }
    else
      {
	  push @INCL_LIB, ( "$base", "$base/lib" );
      }

   unshift @INC, @INCL_LIB;

   $installPath = dirname( dirname $base );
}


use Log;
use CLI::Config;

use OS;
use ClearCase;
use TaBasCo;


# ensure umask with 002, to guarantee correct directory permissions
umask( 002 );

# Execute the main() programm
exit &main();

# ============================================================================

sub main()
{
   eval {
      if ( not defined $ARGV[0] )
      {
         @ARGV = ( 'helpText' );
      }

      # check if user has entered a shortcut
      my $cmd =
         defined $CLI::Config::COMMAND_SHORTCUT{ $ARGV[0] }
         ? $CLI::Config::COMMAND_SHORTCUT{ $ARGV[0] }
         : $ARGV[0];

      if ( defined $CLI::Config::COMMAND{ $cmd } )
      {
         my $package = $CLI::Config::COMMAND{$cmd}->{'package'};
         Debug3( [ 'Need package ' . $package ] );

         Die( [ $cmd . ' not implemented' ] )
            if not defined $package;

         unless ( eval ( "require $package" ) ) {
            Die( $@ );
         }

         # remove '<command>' from @ARGV
         @ARGV = @ARGV[ 1 .. $#ARGV ];

         # create instance of application
         Debug5( [ 'Creating application object' ] );
         my $appl = $package->new();

         # execute command
         Debug5( [ 'Calling application main() method' ] );
         $appl->main( $cmd );

         return 0;
      }
      else
      {
         print 'Unknown command: ' . $cmd . "\n";
         return -1;
      }
   };
   print $@ if $@ ;

} # main ()


__END__

#############################################################################

=pod

=head1 AUTHOR INFORMATION

 Copyright (C) 2001 Uwe Satthoff; satthoff@icloud.com 

=cut

:endofperl
