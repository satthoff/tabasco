package ClearCase::Common::Time;

use strict;
use Carp;


sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $DATE2TIME $TIME2DATE);
   $VERSION = '1.0';
   require Exporter;

   @ISA = qw(Exporter);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   unless( defined $ENV{ATRIAHOME} ) {
    $ENV{ATRIAHOME} = '/usr/atria';
   }
   $DATE2TIME = $ENV{ATRIAHOME} . '/etc/utils/date2time';
   $TIME2DATE = $ENV{ATRIAHOME} . '/etc/utils/time2date';

} # sub BEGIN()

sub mon
  {
      my $digit = shift;
      my @month = qw/ Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec /;
      return $month[ $digit ];
  }

sub _getCCTime
  {
      my @tA = @_;
      $tA[4] = mon( $tA[4] );
      $tA[5] = 1900 + $tA[5];
      $tA[5] =~ s/^\d\d//;
      return "$tA[3]-$tA[4]-$tA[5].$tA[2]:$tA[1]:$tA[0]";
  }

sub getActualUTC
  {
      return _getCCTime( gmtime( time ) ) . 'UTC';
  }

sub getActualLOC
  {
      return _getCCTime( localtime( time ) );
  }


sub convertCCtimeToEpochSec {
   my $ccTime = "@_";

   my %digitMonth = ( 'Jan' => 0,
		      'Feb' => 1,
		      'Mar' => 2,
		      'Apr' => 3,
		      'May' => 4,
		      'Jun' => 5,
		      'Jul' => 6,
		      'Aug' => 7,
		      'Sep' => 8,
		      'Oct' => 9,
		      'Nov' => 10,
		      'Dec' => 11
		    );

   my $ccUTC = CCtoUTC( $ccTime );
   $ccUTC =~ s/UTC$//;
   $ccUTC =~ m/^(\d+)\-(\S+)\-(\d+)(.*)/;
   my ( $day, $month, $year, $rest ) = ( int $1, $digitMonth{$2}, int $3, $4 );
   my $hour = 0;
   my $min  = 0;
   my $sec  = 0;
   if ( $rest )
     {
	 $rest =~ s/^\.//;
	 my @x = split /:/, $rest;
	 $hour = int $x[0] if ( $#x >= 0 );
	 $min  = int $x[1] if ( $#x >= 1 );
	 $sec  = int $x[2] if ( $#x == 2 );
     }
   
   require Time::Local;
   return Time::Local::timegm($sec,$min,$hour,$day,$month,$year);
}

sub CCtoUTC
  {
      my $locCC = shift;

      return $locCC if ( $locCC =~ m/UTC$/ ); # it is already UTC format

      # here we expect $locCC to be local time in CC format
      my @utc = gmtime( time );
      my @loc = localtime( time );
      my $diffHour = $loc[2] - $utc[2];
      if ( $locCC =~ m/^(\S+\.)(\d\d)(:.*)/ )
	{
	    my $first = $1;
	    my $hour = $2;
	    my $rest = $3;
	    $hour = int( $hour ) - $diffHour;
	    $locCC = $first . $hour . $rest . 'UTC';
	}
      return $locCC;
  }

sub CCtoLOC
  {
      my $locCC = shift;

      return $locCC unless ( $locCC =~ m/UTC$/ ); # it is already local format

      # here we expect $locCC to be UTC time in CC format
      my @utc = gmtime( time );
      my @loc = localtime( time );
      my $diffHour = $loc[2] - $utc[2];
      if ( $locCC =~ m/^(\S+\.)(\d\d)(:.*)UTC$/ )
	{
	    my $first = $1;
	    my $hour = $2;
	    my $rest = $3;
	    $hour = int( $hour ) + $diffHour;
	    $locCC = $first . $hour . $rest;
	}
      return $locCC;
  }

1;

__END__

=head1 EXAMPLES

=head1 AUTHOR INFORMATION

 Copyright (C) 2007 Uwe Satthoff

=head1 BUGS

 Address bug reports and comments to:
   uwe@satthoff.eu

=head1 SEE ALSO

=cut

# ============================================================================
