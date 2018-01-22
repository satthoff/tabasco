package ClearCase::Element;

use strict;
use Carp;
use File::Basename;
use Log;

BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;
   require Data;
   require ClearCase::Common::CCPath;

   @ISA = qw(Exporter Data ClearCase::Common::CCPath );

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   %DATA = (
       CspecPath      => { CALCULATE => \&loadCspecPath }
      );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'ClearCase::Common::CCPath'
      );

} # BEGIN()

# constructor new is in ClearCase::Common::CCPath

sub loadCspecPath
  {
      my $self  = shift;

      my $vobHome = $self->getVob()->getTag();
      $vobHome =~ s/\\/\//g; # always UNIX style
      my $qvobHome = quotemeta( $vobHome );
      my $normPath = $self->getNormalizedPath(); # it is in UNIX style
      my $p = $normPath;
      if( $normPath =~ m/^\/\/view\/[^\/]+$qvobHome\/|^\/\/view\/[^\/]+${qvobHome}$/ )
	{
	  # UNIX or Windows version extended
	  $p =~ s/^\/\/view\/[^\/]+$qvobHome//;
	}
      elsif( $normPath =~ m/^\S:\/[^\/]+$qvobHome\/|^\S:\/[^\/]+${qvobHome}$/ )
	{
	  # Windows drive letter
	  $p =~ s/^\S:\/[^\/]+$qvobHome//;
	}
      elsif( $normPath =~ m/^$qvobHome\/|^${qvobHome}$/ )
	{
	  # no view information in path
	  $p =~ s/^$qvobHome//;
	}
      else
	{
	  Die( [ '', __PACKAGE__ . "::loadCspecPath : wrong norm path >$normPath<", '' ] );
	}
      $p =~ s/\\/\//g;
      $p =~ s/\/\.$//;
      $p =~ s/\/+/\//g;
      $p = '' if( $p eq '/' );
      my $cspecPath = $self->getVob()->getCspecTag() . $p . '/...';
      $cspecPath =~ s/\\/\//g; # always UNIX style
      return $self->setCspecPath( $cspecPath );
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

##############################################################################

