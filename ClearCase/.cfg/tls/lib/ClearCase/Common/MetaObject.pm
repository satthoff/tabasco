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
       GlobalAndAcquire => undef
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
       Die( [ __PAACKAGE__ , 'Wrong object initialization. Expecting to be a ClearCase::Vob object' ] ) unless( $self->isa( 'ClearCase::Vob' ) );
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
	       Die( [ '', 'Wrong object initialization in ' .  __PACKAGE__ . ". Missing type specification.", '' ] ) unless( $type );
	       $typeName = $type;
	       $name = $1;
	       $vobTag = $2;
	   } elsif( $name !~ m/:|\@/ ) {
	       Die( [ '', 'Wrong object initialization in ' .  __PACKAGE__ . ". Missing type specification.", '' ] ) unless( $type );
	       Die( [ '', 'Wrong object initialization in ' .  __PACKAGE__ . ". Missing Vob specification.", '' ] ) unless( $vob );
	       $typeName = $type;
	       $vobTag = $vob->getTag();
	   } else {
	       Die( [ '', 'Wrong object initialization in ' .  __PACKAGE__ . " with name = $name", "Possibly missing type and/or Vob specification.", '' ] );
	   }

	   Die( [ '', 'Wrong object initialization in ' .  __PACKAGE__ . ". Unknown object type = $typeName.", '' ] ) unless( grep m/^${typeName}$/, @knownTypes );

	   $self->setType( $typeName );
	   $self->setName( $name );
	   my @vobConfig = $ClearCase::Common::Config::myHost->getRegion()->getVob( $vobTag )->typeCreationConfig();
	   $self->setGlobalAndAcquire( $vobConfig[0] );
	   $self->setVob( $vobConfig[1] );
	   $self->setFullName( $typeName . ':' . $name . "\@$vobTag" );
   }
   return $self;
}

sub exists {
    my $self = shift;

    return 1 if( $self->getExists() );
    ClearCase::disableErrorOut();
    ClearCase::disableDieOnErrors();
    ClearCase::describe(
	-argv => $self->getFullName(),
	-short    => 1
	);
    my $ex = ( ClearCase::getRC() == 0 );
    ClearCase::enableErrorOut();
    ClearCase::enableDieOnErrors();
    $self->setExists( 1 ) if( $ex );
    return $ex;
}

sub getFromHyperlinkedObjects {
    my $self = shift;
    my $hltype = shift; # we expect an object of class ClearCase::HlType

    Die( [ __PACKAGE__ . '::getFromHyperlinkedObjects', 'FATAL ERROR: subroutine parameter is not a ClearCase::HlType' ] ) unless( $hltype->isa( 'ClearCase::HlType' ) );

    my $hltypeName => $hltype->getName();
    ClearCase::describe(
	-long => 1,
	-ahl => $hltypeName,
	-argv => $self->getFullName()
	);
    my @results = ClearCase::getOutput();
    grep chomp, @results;

    # get the hyperlink lines
    @results = grep m/$hltypeName\@/, @results;
    return @results unless( @results );

    # get only the from hyperlinks
    @results = grep m/\->/, @results;
    return @results unless( @results );

    # reduce to object identifiers, which are Meta objects or Vob pathnames
    my @objectIdentifiers = ();
    foreach my $line ( @results ) {
	my @tmp = split /\s+/, $line;
	push @objectIdentifiers, $tmp[$#tmp];
    }
    
    return \@objectIdentifiers;
}

sub getToHyperlinkedObjects {
    my $self = shift;
    my $hltype = shift; # we expect an object of class ClearCase::HlType

    Die( [ __PACKAGE__ . '::getToHyperlinkedObjects', 'FATAL ERROR: subroutine parameter is not a ClearCase::HlType' ] ) unless( $hltype->isa( 'ClearCase::HlType' ) );

    my $hltypeName => $hltype->getName();
    ClearCase::describe(
	-long => 1,
	-ahl => $hltypeName,
	-argv => $self->getFullName()
	);
    my @results = ClearCase::getOutput();
    grep chomp, @results;

    # get the hyperlink lines
    @results = grep m/$hltypeName\@/, @results;
    return @results unless( @results );

    # get only the to hyperlinks
    @results = grep m/<\-/, @results;
    return @results unless( @results );

    # reduce to object identifiers, which are Meta objects or Vob pathnames
    my @objectIdentifiers = ();
    foreach my $line ( @results ) {
	my @tmp = split /\s+/, $line;
	push @objectIdentifiers, $tmp[$#tmp];
    }
    
    return \@objectIdentifiers;
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
