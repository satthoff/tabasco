package ClearCase::Common::CCPath;

use strict;
use Carp;
use File::Basename;
use Log;
require ClearCase::Version;


BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;
   require Data;

   @ISA = qw(Exporter Data);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   %DATA = (
       Oid => undef,
       Vob    => { CALCULATE => \&loadVob },
       NormalizedPath => { CALCULATE => \&loadNormalizedPath }
      );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => ''
      );

} # BEGIN()

sub new()
{
   my $proto = shift;
   my $class = ref ($proto) || $proto;
   my $self  = {};
   bless $self, $class;

   my ( $pathname, @other ) = $self->rearrange(
      [ 'PATHNAME' ],
      @_ );
   confess @other if @other;

   Die( [ "Missing argument pathname for initilization of object $class" ] ) unless( $pathname );

   if( $self->isa( 'ClearCase::Branch' ) ) {
       # the specified branch path might not exist yet,
       # only initialization for the on disk object creation
       ClearCase::disableErrorOut();
       ClearCase::disableDieOnErrors();
       ClearCase::describe(
	   -pathname => $pathname,
	   -fmt => '%m'
	   );
       ClearCase::enableErrorOut();
       ClearCase::enableDieOnErrors();
   } else {
       ClearCase::describe(
	   -pathname => $pathname,
	   -fmt => '%m'
	   );
   }
   if( ClearCase::getRC() == 0 ) {
       my $objKind = ClearCase::getOutputLine();
       chomp $objKind;

       if( $objKind eq '**null meta type**' ) {
	   # we are not within a Vob
	   return undef;
       }

       $objKind =~ s/^\S+\s//;
       my $correctKind = $class;
       $correctKind =~ s/^.*:://;

       Die( [ "Pathname argument  is not a $class: $pathname" ] ) if( lc( $objKind ) ne lc( $correctKind ) );
       $self->computeMyOid( $pathname );
   }
   
   $self->_init( $pathname );
   return $self;
}

sub loadNormalizedPath {
    my $self = shift;

    my $xpn = $self->getVXPN();
    $xpn =~ s/\\/\//g; # always UNIX style

    # splits any version extended pathname $xpn in its pieces,
    # and returns the path without version information

    my @components = ();

    $xpn =~ s/\@\@$//;
    unless( $xpn =~ m/\@\@.*\@\@/ ) {
	$xpn = $xpn . '@@/main/1';
    }

    $xpn =~ s/\/\.\@\@\//\@\@\//g;
    my @pieces = split ( /\@\@/, $xpn );

    my $version = '';
    my $first = shift @pieces;
    $version = pop @pieces;
    $xpn = join ('', @pieces);

    if ($#pieces > -1) {
	while ($xpn) {
	    push @components, basename($xpn);
	    $xpn = dirname $xpn;
	    if ($xpn =~ m#/main/.*/\d+$#) {
		$xpn =~ s#^(.*)(/main/.*/\d+)$#$1#;
		$version = $2;
	    } else {
		$xpn =~ s#^(.*)(/main/\d+)$#$1#;
		$version = $2;
	    }
        }
    }
    push @components, $first;
    return $self->setNormalizedPath( join "/", reverse @components );
}

sub loadVob {
    my $self  = shift;
    return $self->setVob( $ClearCase::Common::Config::myHost->getRegion()->getVob( -tag => $self->getVXPN() ) );
}

sub getVXPN {
   my $self = shift;

   ClearCase::describe(
       -pathname => 'oid: ' . $self->getOid(),
       -short => 1
       );
   my $p = ClearCase::getOutputLine();
   chomp $p;
   return $p;
}

sub computeMyOid {
    my $self = shift;
    my $path = shift;

       ClearCase::describe(
       -pathname => $path,
       -fmt => '%On'
       );
   my $oid = ClearCase::getOutputLine();
   $self->setOid( $oid );
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

