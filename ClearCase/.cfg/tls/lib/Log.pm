package Log;

use strict;
use Carp;

sub BEGIN {
   # =========================================================================
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
      'all'    => [ qw( Progress Warn Die Error Message Debug Debug1 Debug2 Debug3 Debug4 Debug5 Exec SILENT DEFAULT PROGRESS
      WARNING ALL ERROR MESSAGE DEBUG DEBUG1 DEBUG2 DEBUG3 DEBUG4 DEBUG5 EXECUTE ) ]
   );
   Exporter::export_tags('all');
   # =========================================================================
} # sub BEGIN()

use constant SILENT     => -1;
use constant ERROR      => 10;
use constant WARNING    => 20;
use constant MESSAGE    => 5;
use constant DEFAULT    => 10;
use constant PROGRESS   => 40;
use constant EXECUTE    => 50;
use constant ALL        => 60;
use constant DEBUG      => 70;
use constant DEBUG1     => 75;
use constant DEBUG2     => 80;
use constant DEBUG3     => 85;
use constant DEBUG4     => 90;
use constant DEBUG5     => 95;
use constant NONE       => 100;

use vars qw( $VERBOSITY %VERBOSITY_VALUES);

$VERBOSITY     = DEFAULT;
%VERBOSITY_VALUES = (
   SILENT     => SILENT,
   MESSAGE    => MESSAGE,
   ERROR      => ERROR,
   DEFAULT    => DEFAULT,
   PROGRESS   => PROGRESS,
   EXECUTE    => EXECUTE,
   WARNING    => WARNING,
   ALL        => ALL,
   DEBUG      => DEBUG,
   DEBUG1     => DEBUG1,
   DEBUG2     => DEBUG2,
   DEBUG3     => DEBUG3,
   DEBUG4     => DEBUG4,
   DEBUG5     => DEBUG5
);

# ============================================================================
# Description

=head1 NAME

Log - <short description>

=head1 SYNOPSIS

B<Log.pm> [options]

=head1 DESCRIPTION

<long description>

=head1 USAGE

=head1 METHODS

=cut


=head2 Log ()

<description>

=cut

my %PREFIX = (
   ERROR()       => 'ERR',
   WARNING()     => 'WRN',
   PROGRESS()    => 'PRG',
   EXECUTE()     => 'EXE',
   DEBUG()       => 'DBG'
   );

my $debugLogFile = '';
my $debugFH = undef;

sub Log {
   my ( $ostream, $level, $out, @dbg ) = @_;

   if ( $#dbg != -1 )
   {
      confess "Error";
   }

   if ( $level <= $VERBOSITY )
   {
      # print the level
     if( exists $PREFIX{ $level } )
       {
	 print $PREFIX{ $level }, ": ";
	 print $debugFH $PREFIX{ $level }, ": " if( $debugFH );
       }

     # print the String(s)
     if ( ref $out eq 'ARRAY' )
       {
         require Carp;
         foreach( @$out )
	   {
	     Carp::cluck if not defined $_;
	     chomp;
	     print "\t$_\n";
	     print $debugFH  "\t$_\n" if( $debugFH );
	   }
       }
     else
       {
	 print $out;
	 print $debugFH $out if( $debugFH );
       }
   }
   
} # Log ()

sub Message       { Log( *STDOUT, MESSAGE    , @_ ); }
sub Error         { Log( *STDERR, ERROR      , @_ ); }
sub Die           { Log( *STDERR, ERROR      , @_ );
                    $VERBOSITY >= DEBUG
                    ? confess
                    : die; }
sub Warn          { Log( *STDERR, WARNING    , @_ ); }
sub Progress      { Log( *STDERR, PROGRESS   , @_ ); }
sub Exec          { Log( *STDERR, EXECUTE    , @_ ); }
sub Debug         { # Log( *STDERR, DEBUG      , join( ':', caller() ) . "\n" );
                    Log( *STDERR, DEBUG      , @_ ); }
sub Debug1        { # Log( *STDERR, DEBUG1     , join( ':', caller() ) . "\n" );
                    Log( *STDERR, DEBUG1     , @_ ); }
sub Debug2        { # Log( *STDERR, DEBUG2     , join( ':', caller() ) . "\n" );
                    Log( *STDERR, DEBUG2     , @_ ); }
sub Debug3        { # Log( *STDERR, DEBUG3     , join( ':', caller() ) . "\n" );
                    Log( *STDERR, DEBUG3     , @_ ); }
sub Debug4        { # Log( *STDERR, DEBUG4     , join( ':', caller() ) . "\n" );
                    Log( *STDERR, DEBUG4     , @_ ); }
sub Debug5        { # Log( *STDERR, DEBUG5     , join( ':', caller() ) . "\n" );
                    Log( *STDERR, DEBUG5     , @_ ); }


# ===========================================================================

=head2 METHOD setVerbosity ( $verbosity )

  DESCRIPTION
    Sets the verbosity to new state 'verbosity'. Returns the corresponding
    numerical value.

      Possible Values for $verbosity :
        SILENT     no output
        MESSAGE    only messages
        ERROR      plus errors
        DEFAULT    default setting
        PROGRESS   plus trace information
        EXECUTE    plus executed ct commands
        WARNING    plus warnings
        ALL        all above
        DEBUG      plus debug information level 0
        DEBUG1     plus debug information level 1
        DEBUG2     plus debug information level 2
        DEBUG3     plus debug information level 3
        DEBUG4     plus debug information level 4
        DEBUG5     plus debug information level 5 ( triggers )

  ARGUMENTS
    $verbosity       New value

  RETURN VALUE

=cut

sub setVerbosity {
   my $progress = uc $_[0];

   if ( $VERBOSITY_VALUES{ $progress } ) {
      $VERBOSITY = $VERBOSITY_VALUES{$progress };
      if( $progress =~ m/^DEBUG/ )
	{
	  use File::Temp qw( tempfile );
	  ( $debugFH, $debugLogFile ) = File::Temp::tempfile();
	  Debug( [ '', "debug log file = $debugLogFile", '' ] );
	}
      return $VERBOSITY;

   } else {
      Die("Value $_[0] is not valid for option --verbosity!");

   }

  ### never reached
  die;

} # setVerbosity



# ============================================================================
# Autoload methods go after =cut, and are processed by the autosplit program.
#
# remeber to
#  require AutoLoader

1;

__END__

=head1 EXAMPLES

=head1 AUTHOR INFORMATION

 Copyright (C) 2004 Uwe Satthoff (satthoff@icloud.com)

=head1 CREDITS

=head1 BUGS

 Address bug reports and comments to:
   satthoff@icloud.com

=head1 SEE ALSO

=cut

