package ClearCase::Common::CCPath;

use strict;
use Carp;
use File::Basename;
use Log;


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
       Vob => undef,
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

   # determine my Vob
   ClearCase::disableErrorOut();
   ClearCase::disableDieOnErrors();
   ClearCase::describe(
       -pathname => 'vob:' . $pathname,
       -short => 1
       );
   ClearCase::enableErrorOut();
   ClearCase::enableDieOnErrors();

   if( ClearCase::getRC() != 0 ) {
       # pathname is not a VXPN (path within a Vob)
       return undef;
   }
   my $vobTag = ClearCase::getOutputLine();
   chomp $vobTag;
   # get the Vob from my ClearCase host region
   $self->setVob( $ClearCase::Common::Config::myHost->getRegion()->getVob( -tag => $vobTag ) );

   # determine my OID
   ClearCase::describe(
       -pathname => $pathname,
       -fmt => '%On'
       );
   $self->setOid( ClearCase::getOutputLine() );
   
   $self->_init();
   return $self;
}

sub _init {
    my $self = shift;

    # exists here only to ensure that a subroutine _init exists in the class hierachy,
    # because sibling classes might not declare a _init subroutine.
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
    return $self->setNormalizedPath( join "$OS::Common::Config::slash", reverse @components );
}

sub getVXPN {
   my $self = shift;

   ClearCase::describe(
       -pathname => 'oid: ' . $self->getOid() . '@' . $self->getVob()->getTag(),
       -short => 1
       );
   my $p = ClearCase::getOutputLine();
   chomp $p;
   return $p;
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

