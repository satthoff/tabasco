package ClearCase::Common::XPN;

use strict;
use Carp;
use File::Basename;
use ClearCase::Oid;


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

sub getComponents {
   my ( $xpn, $bFirst ) = @_;

   my( $element, $version, $rest ) = getNextComponent( $xpn, not defined $bFirst );

   my @pieces;
   push @pieces, [ $element, $version ];
   push @pieces, ( getComponents( $rest, not defined $bFirst ) )
      if defined $rest and $rest ne '';

   return @pieces;
} # getComponents

sub getNextComponent {

   my ( $string, $first ) = @_;
   my $element ;
   my $version;
   my $rest    ;

   if( $first )
   {
      if( $string  =~ m#\@\@$# )
      {
         $rest    = undef;
      }
      elsif( $string  =~ s#\@\@(.+)## )
      {
         $rest    = $1;
      }
   }
   else
   {
      if( $string  =~ m#\@\@$# )
      {
         $rest    = undef;
      }
      elsif( $string  =~ s#(?:\@\@|)(/.+)## )
      {
         $rest    = $1;
      }
   }

   $element = $string;
   $version = $1  if defined $rest and $rest =~ s#(/main.*?/\d+)/?##;

   return ( $element, $version, $rest );
} # getNextComponent

sub getNextSortedComponents {
   my ( $xpn ) = @_;

   # splits the version extended pathname $xpn in its pieces,
   # and in array @components it returns for each part of $xpn
   # an array = [ name of element, version of element, OID of element ]

   my @components = ();

   # change always to UNIX style
   $xpn =~s/\\/\//g if( defined $ENV{ OS } );

   $xpn =~ s/\/\.\@\@\//\@\@\//g;
   my @pieces = split ( /\@\@/, $xpn );

   my $version = '';
   my $first = shift @pieces;
   $version = pop @pieces;
   $xpn = join ('', @pieces);

   if ($#pieces > -1)
     {
      while ($xpn)
        {
         push @components, [ basename($xpn), $version, ClearCase::Oid::PathToOid( $first . '@@' . $xpn . '@@' ) ];
         $xpn = dirname $xpn;
         if ($xpn =~ m#/main/.*/\d+$#)
             {
              $xpn =~ s#^(.*)(/main/.*/\d+)$#$1#;
              $version = $2;
             }
         else
             {
              $xpn =~ s#^(.*)(/main/\d+)$#$1#;
              $version = $2;
             }
        }
     }
   push @components, [ $first, $version, ClearCase::Oid::PathToOid( $first . '@@' ) ];
   return @components;
} # getNextSortedComponents

sub getNormalizedPath
  {
   my ( $xpn ) = @_;

   # splits the version extended pathname $xpn in its pieces,
   # and returns the path without version informations

   my @components = ();

   # change always to UNIX style
   $xpn =~s/\\/\//g if( defined $ENV{ OS } );

   $xpn =~ s/\@\@$//;
   unless( $xpn =~ m/\@\@.*\@\@/ )
     {
	 $xpn = $xpn . '@@/main/1';
     }

   $xpn =~ s/\/\.\@\@\//\@\@\//g;
   my @pieces = split ( /\@\@/, $xpn );

   my $version = '';
   my $first = shift @pieces;
   $version = pop @pieces;
   $xpn = join ('', @pieces);

   if ($#pieces > -1)
     {
      while ($xpn)
        {
         push @components, basename($xpn);
         $xpn = dirname $xpn;
         if ($xpn =~ m#/main/.*/\d+$#)
             {
              $xpn =~ s#^(.*)(/main/.*/\d+)$#$1#;
              $version = $2;
             }
         else
             {
              $xpn =~ s#^(.*)(/main/\d+)$#$1#;
              $version = $2;
             }
        }
     }
   push @components, $first;
   return join "/", reverse @components;
  }

sub getSortedComponents
  {
      my $args = shift;
      
      # returns a sorted array (directories first, then the contents of directories)
      # with always two related elements in sequence, first the OID of the CC element
      # and second a string of versions seperted by blanckk to be merged from.
      #
      # sorting will be performed independently of the current view's config spec. For
      # sorting it will be assumed, that each element version is directly visible, means
      # would be selected by the current config spec (whatever it is).
      
      my %elements = ();
      my @result = ();
      my @allStrings = ();
      if ( ref $args eq 'ARRAY' )
	{
	    @allStrings = @$args;
	}
      else
	{
	    push @allStrings, $args;
	}
      
      my $vxpn = '';
      foreach $vxpn (@allStrings)
	{
	    my @pieces = getNextSortedComponents( $vxpn );
	    my $prev = '';
	    my $item = '';
	    while ( $item = pop @pieces )
	      {
		  push @{ $elements{ $prev . @$item[0] } }, "@$item[1] @$item[2]";
		  $prev = $prev . @$item[0] . '/';
	      }
	}
      my $actResult;
      foreach $actResult (  sort { length( $a ) <=> length ( $b ) } keys %elements )
	{
	    my $oid = '';
	    my @allVersions = ();
	    foreach (@{$elements{ $actResult }})
	      {
		  my ($actVersion, $actOid) = split /\s+/;
		  if ($oid eq '')
		    {
			$oid = $actOid;
			push @allVersions, $actVersion;
		    }
		  else
		    {
			my $pattern = quotemeta $actVersion;
			my @exists = grep (m/^${pattern}$/, @allVersions);
		  push @allVersions, $actVersion unless( @exists );
	      }
	}
      my $versions = join (" ", @allVersions);
      my $eltype = '';
      ClearCase::describe(
			  -pathname => 'oid:' . $oid,
			  -fmt      => '\'%[type]p\''
			 );
      $eltype =  ClearCase::Common::Cleartool::getOutputLine();
      chomp $eltype;
      push @result, [ $oid, $versions, $eltype ];
  }
   return @result;
}

1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

  Copyright (C) 2007, 2010 Uwe Satthoff
   satthoff@icloud.com

=cut

