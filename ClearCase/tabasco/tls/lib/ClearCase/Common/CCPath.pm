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
       PathType => undef,
       CspecPath => { CALCULATE => \&loadCspecPath },
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
   Die( [ 'Fatal Error. Package ' . __PACKAGE__ . ' can only be used as parent package of',
	  'ClearCase::Element, ClearCase::Branch or ClearCase::Version.' ] )
       if( ( not $self->isa( 'ClearCase::Element' ) and
	     not $self->isa( 'ClearCase::Branch' ) and
	     not $self->isa( 'ClearCase::Version' ) ) );

   # determine my Vob
   ClearCase::disableErrorOut();
   ClearCase::disableDieOnErrors();
   ClearCase::describe(
       -argv => 'vob:' . $pathname,
       -short => 1
       );
   ClearCase::enableErrorOut();
   ClearCase::enableDieOnErrors();

   if( ClearCase::getRC() != 0 ) {
       # pathname is not a VXPN (path within a Vob)
       # or should we Die in this case?
       return undef;
   }
   my $vobTag = ClearCase::getOutputLine();
   chomp $vobTag;
      
   # Dependent on the class - ClearCase::Element, ClearCase::Branch, ClearCase::Version - we have to check
   # and possibly to change the provided $pathname according to the currently active ClearCase view.
   #
   # e.g. $self->isa( 'ClearCase::Version' )
   #
   # the pathType (see below) can be:
   #     file element
   #     directory element
   #     directory version
   #     version
   #     branch
   ClearCase::describe(
       -fmt => '%m',
       -argv => $pathname );
   my $pathType = ClearCase::getOutputLine();
   chomp $pathType;
   $pathType =~ s/^\s*(.*)\s*$/$1/; # strip off leading and trailing white spaces
   $pathType =~ s/^\S+\s//; # reduce to simple string value: element, branch or version.

   if( ( $self->isa( 'ClearCase::Element' ) and $pathType ne 'element' ) or
       ( $self->isa( 'ClearCase::Branch' ) and $pathType ne 'branch' ) or
       ( $self->isa( 'ClearCase::Version' ) and $pathType ne 'version' ) ) {
       # THEN: something to be done with pathname

       # ensure to have in variable $pathname really the version extended pathname
       ClearCase::describe(
	   -argv => $pathname,
	   -fmt => '%Xn'
	   );
       $pathname = ClearCase::getOutputLine();
       chomp $pathname;

       if( $pathType eq 'version' and $self->isa( 'ClearCase::Branch' ) ) {
	   # strip off the trailing number
	   $pathname = File::Basename::dirname( $pathname );
       } elsif( ( $pathType eq 'version' and $self->isa( 'ClearCase::Element' ) ) or
		( $pathType eq 'branch' and $self->isa( 'ClearCase::Element' ) ) ) {
	   # strip off the trailing branch or version identifier
	   $pathname =~ s/^(\S+\@\@).*/$1/;
       } else {
	   Die( [ '', 'Package: ' . __PACKAGE__ . ' ( check the inconsitency! )',
		  'Pathname: ' . $pathname,
		  'PathType: ' . $pathType,
		  'Class: ' . $class, '' ] );
       }
   }

   # save the path type - version,branch,element
   # we need it in subroutine loadNormalizedPath later
   $self->setPathType( $pathType );

   # determine my OID
   # PROBLEM - still to be solved:
   #    if the $pathname is a CHECKEDOUT version,
   #    then we cannot use the OID as a unique identification,
   #    because after checkin the OID of the checkedin version is different.
   #    The OID of a CHECKEDOUT version is only valid as long the CHECKOUT exists.
   ClearCase::describe(
       -argv => $pathname,
       -fmt => '%On'
       );
   my $oid = ClearCase::getOutputLine();
   chomp $oid;
   $self->setOid( $oid );

   $self->setVob( $ClearCase::Common::Config::myHost->getRegion()->getVob( $vobTag ) );
   
   $self->_init();
   return $self;
}

sub _init {
    my $self = shift;

    # exists here only to ensure that a subroutine _init exists in the class hierachy,
    # because child classes might not declare a _init subroutine.
    return $self;
}

sub loadNormalizedPath {
    my $self = shift;

    my $xpn = $self->getVXPN();
    $xpn =~ s/\\/\//g; # always UNIX style

    # splits any version extended pathname $xpn in its pieces,
    # and returns the path without version information

    my @components = ();

    if( $self->getPathType() eq 'element' ) {
	# we expect an element path to end with @@
	$xpn =~ s/\@\@$//;
    } elsif( $self->getPathType() eq 'branch' ) {
	# we expect a branch path to end with @@/<some branches>
	$xpn =~ s/\@\@\/.*//;
    }

    unless( $xpn =~ m/\@\@.*\@\@/ ) {
	$xpn = $xpn . '@@/main/1'; # append dummy version string to let the following algorithm work
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

sub loadCspecPath {
    my $self  = shift;

    my $vobHome = $self->getVob()->getTag();
    $vobHome =~ s/\\/\//g; # always UNIX style
    my $qvobHome = quotemeta( $vobHome );
    my $normPath = $self->getNormalizedPath(); # it is in UNIX style
    my $p = $normPath;
    if( $normPath =~ m/^\/\/view\/[^\/]+$qvobHome\/|^\/\/view\/[^\/]+${qvobHome}$/ ) {
	# UNIX or Windows version extended
	$p =~ s/^\/\/view\/[^\/]+$qvobHome//;
    } elsif( $normPath =~ m/^\S:\/[^\/]+$qvobHome\/|^\S:\/[^\/]+${qvobHome}$/ ) {
	# Windows drive letter
	$p =~ s/^\S:\/[^\/]+$qvobHome//;
    } elsif( $normPath =~ m/^$qvobHome\/|^${qvobHome}$/ ) {
	# no view information in path
	$p =~ s/^$qvobHome//;
    } else {
	Die( [ '', __PACKAGE__ . "::loadCspecPath : wrong norm path >$normPath<", '' ] );
    }
    $p =~ s/\\/\//g;
    $p =~ s/\/\.$//;
    $p =~ s/\/+/\//g;
    $p = '' if( $p eq '/' );
    my $cspecPath = $self->getVob()->getCspecTag() . $p . '/...';
    $cspecPath =~ s/\\/\//g; # always UNIX style

    # above we do not care about double slashes in the pathname.
    # but we want to return a clean path
    $cspecPath =~ s/\/+/\//g;
    
    return $self->setCspecPath( $cspecPath );
}

sub getVXPN {
   my $self = shift;

   # the composition of the version extended pathname depends on the
   # config spec of the currently active view.
   # therefore we use the format option '%Xn'.
   ClearCase::describe(
       -argv => 'oid:' . $self->getOid() . '@' . $self->getVob()->getTag(),
       -fmt => '%Xn'
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
   satthoff@icloud.com

=head1 SEE ALSO

=cut

##############################################################################

