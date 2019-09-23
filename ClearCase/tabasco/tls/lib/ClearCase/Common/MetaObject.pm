package ClearCase::Common::MetaObject;

use strict;
use Carp;

use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;

   @ISA = qw(Exporter Data);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   %DATA = (
       Name => undef,
       Type => undef,
       Vob => undef,
       FullName => undef,
       Exists => undef,
       AdminVob => { CALCULATE => \&loadAdminVob },
       AdminMode => { CALCULATE => \&loadAdminMode }
      );

   require Data;
   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => undef
      );

} # sub BEGIN()

# still to be done for UCM types, stream, activity, baseline, .....
my @knownTypes = qw/ brtype lbtype attype hltype trtype eltype replica vob /;

sub new {
   my $proto = shift;
   my $class = ref( $proto ) || $proto;
   my $self  = {};
   bless( $self, $class );

   return $self->_init( @_ );
} # new

sub _init {
   my $self = shift;

   my ( $type, $name, $vob, @other ) = $self->rearrange(
      [ 'TYPE', 'NAME', 'VOB' ],
      @_ );

   if( $name =~ m/^vob:/ or $type and $type eq 'vob' ) {
       Die( [ __PACKAGE__ , 'Wrong object initialization. Expecting to be a ClearCase::Vob object' ] ) unless( $self->isa( 'ClearCase::Vob' ) );
       $name =~ s/^vob://;
       $name =~ s/\@.*//;
       $self->setName( $name );
       $self->setVob( $self );
       $self->setFullName( 'vob:' . $name );
   } else {
       # the type and vob arguments will only be used/checked, if the appropriate information is not encoded in the name argument
       my $typeName = '';
       my $vobTag = '';
   
       if( $name =~ m/^\s*(\S+):(\S+)\@(\S+).*$/ ) {
	   $typeName = $1;
	   $name = $2;
	   $vobTag = $3;
       } elsif( $name =~ m/^\s*(\S+)\@(\S+).*$/ ) {
	   Die( [ __PACKAGE__ , 'Wrong object initialization. Missing type specification.' ] ) unless( $type );
	   $typeName = $type;
	   $name = $1;
	   $vobTag = $2;
       } elsif( $name !~ m/:|\@/ ) {
	   Die( [ __PACKAGE__ , 'Wrong object initialization. Missing type specification.' ] ) unless( $type );
	   Die( [ __PACKAGE__ , 'Wrong object initialization. Missing Vob specification.' ] ) unless( $vob );
	   $typeName = $type;
	   $vobTag = $vob->getTag();
       } else {
	   Die( [ __PACKAGE__ , "Wrong object initialization with name = $name", "Possibly missing type and/or Vob specification." ] );
       }

       Die( [ __PACKAGE__ , "Wrong object initialization. Unknown object type = $typeName." ] ) unless( grep m/^${typeName}$/, @knownTypes );

       # ensure the correct Vob element
       $vob = $ClearCase::Common::Config::myHost->getRegion()->getVob( $vobTag );

       # set MetaObject attributes
       $self->setType( $typeName );
       $self->setName( $name );
       $self->setVob( $vob );
       $self->setFullName( $self->getType() . ':' . $self->getName() . '@' . $self->getVob()->getTag() );
   }
   return $self;
}

sub exists {
    my $self = shift;

    return 1 if( $self->getExists() );
    ClearCase::disableErrorOut();
    ClearCase::disableDieOnErrors();
    my $myName = $self->getFullName();
    if( $myName !~ m/^vob:/ and $self->getVob()->getTag() ne $self->getAdminVob()->getTag() ) {
	# in case of an Admin Vob exists for my Vob then we have to question
	# for the existence in the Admin Vob, because the local copy of the global meta object
	# may not already exist.
	$myName = $self->getType() . ':' . $self->getName() . '@' . $self->getAdminVob()->getTag();
    }
    ClearCase::describe(
	-argv => $myName,
	-short    => 1
	);
    my $ex = ( ClearCase::getRC() == 0 );
    ClearCase::enableErrorOut();
    ClearCase::enableDieOnErrors();
    $self->setExists( 1 ) if( $ex );
    return $ex;
}

sub loadAdminVob {
    my $self = shift;

    return $self->setAdminVob( $self->getVob()->getAdminVobHierarchyRoot() );
}

sub loadAdminMode {
    my $self = shift;

    my $adminMode = 0;
    $adminMode = 1 if( $self->getVob()->getClientVobs() or $self->getVob()->getMyAdminVob() );
    return $self->setAdminMode( $adminMode );
}

sub lock {
    my $self = shift;

    my ( $obsolete, @other ) = $self->rearrange(
	[ 'OBSOLETE' ],
	@_ );

    ClearCase::lock(
	-obsolete => $obsolete,
	-object   => $self->getFullName()
	);
}

sub unlock {
    my $self = shift;

    ClearCase::unlock( -object => $self->getFullName() );
}

sub getFromHyperlinkedObjects {
    my $self = shift;
    my $hltype = shift; # we expect an object of class ClearCase::HlType

    Die( [ __PACKAGE__ . '::getFromHyperlinkedObjects', 'FATAL ERROR: subroutine parameter is not a ClearCase::HlType' ] ) unless( $hltype->isa( 'ClearCase::HlType' ) );

    # use always option -local, because we do not expect hyperlinks between global type in an parent Admin Vob
    ClearCase::describe(
	-localquery => 1,
	-short => 1,
	-ahl => $hltype->getName(),
	-argv => $self->getFullName()
	);
    my @results = ClearCase::getOutput();
    grep chomp, @results;

    # get only the from hyperlinks
    @results = grep m/\->/, @results;
    return @results unless( @results );

    # reduce to object identifiers, which are Meta objects or Vob pathnames
    my @objectIdentifiers = ();
    foreach my $line ( @results ) {
	my @tmp = split /\s+/, $line;
	push @objectIdentifiers, $tmp[$#tmp];
    }
    
    return @objectIdentifiers;
}

sub getToHyperlinkedObjects {
    my $self = shift;
    my $hltype = shift; # we expect an object of class ClearCase::HlType

    Die( [ __PACKAGE__ . '::getToHyperlinkedObjects', 'FATAL ERROR: subroutine parameter is not a ClearCase::HlType' ] ) unless( $hltype->isa( 'ClearCase::HlType' ) );

    # use always option -local, because we do not expect hyperlinks between global type in an parent Admin Vob
    ClearCase::describe(
	-localquery => 1,
	-short => 1,
	-ahl => $hltype->getName(),
	-argv => $self->getFullName()
	);
    my @results = ClearCase::getOutput();
    grep chomp, @results;

    # get only the to hyperlinks
    @results = grep m/<\-/, @results;
    return @results unless( @results );

    # reduce to object identifiers, which are Meta objects or Vob pathnames
    my @objectIdentifiers = ();
    foreach my $line ( @results ) {
	my @tmp = split /\s+/, $line;
	push @objectIdentifiers, $tmp[$#tmp];
    }
    
    return @objectIdentifiers;
}


sub createHyperlinkFromObject {
   my $self = shift;

   my ( $hltype, $object, @other ) = $self->rearrange(
      [ 'HLTYPE', 'OBJECT' ],
       @_ );

   Die( [ __PACKAGE__ . '::createHyperlinkFromObject', 'FATAL ERROR: subroutine parameter is not a ClearCase::HlType' ] ) unless( $hltype->isa( 'ClearCase::HlType' ) );
   
   my $registerLink = ClearCase::HyperLink->new(
       -hltype => $hltype,
       -from => $object,
       -to => $self
       );
   $registerLink->create();
}

sub createHyperlinkToObject {
   my $self = shift;

   my ( $hltype, $object, @other ) = $self->rearrange(
      [ 'HLTYPE', 'OBJECT' ],
       @_ );
   
   Die( [ __PACKAGE__ . '::createHyperlinkToObject', 'FATAL ERROR: subroutine parameter is not a ClearCase::HlType' ] ) unless( $hltype->isa( 'ClearCase::HlType' ) );
  
   my $registerLink = ClearCase::HyperLink->new(
       -hltype => $hltype,
       -from => $self,
       -to => $object
       );
   $registerLink->create();
}
1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2006 Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com

=head1 SEE ALSO

=cut
