package ClearCase::Vob;

use strict;
use Carp;
use Log;

sub BEGIN {
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
       Tag            => undef,
       Password   => undef,
       Exists         => undef,

       AdminVob => { CALCULATE => \&loadVob },            # will be set to 1 (true) if the vob is an administrative vob
       MyAdminVob => { CALCULATE => \&loadVob },          # will contain the Vob object of the adminstrative vob of this vob, if this vob is a vob client.
                                                          # if this vob is not a client of an administrative vob then this attribute will be set to undef.
                                                          #
                                                          # The creation of type objects (currently only implemented for hyperlink, label and branch types)
                                                          # depends on the setting of these two attributes: AdminVob, MyAdminVob.
                                                          # It is guaranteed that new type objects will only be created as ordinary type objects if
                                                          # both attributes are set to 0 resp. undef.
                                                          # Otherwise new type objects will be created in the appropriate admin vob as global type objects.

       LabelTypes => { CALCULATE => \&loadLabelTypes },   # we do not use the "cashing by load subroutines" fully implemented, because
       BranchTypes => { CALCULATE => \&loadBranchTypes }, # the number of existing label or branch types could easily go into the thousands,
                                                          # so loading all existing type objects could decrease the performance heavily.
                                                          # see implementation of subroutines loadLabelTypes and loadBranchTypes

       HyperlinkTypes => { CALCULATE => \&loadHyperlinkTypes },
       ElementTypes => { CALCULATE => \&loadElementTypes },
       TriggerTypes => { CALCULATE => \&loadTriggerTypes },
       RootElement => { CALCULATE => \&loadRootElement },
       Name         => { CALCULATE => \&loadName },
       Hostname  => { CALCULATE => \&loadVob },
       Owner        => { CALCULATE => \&loadVob },
       Hpath         => { CALCULATE => \&loadVob },
       Gpath         => { CALCULATE => \&loadVob },
       MyReplica   => { CALCULATE => \&loadMyReplica },
       AllReplica    => { CALCULATE => \&loadAllReplica },
       CspecTag   => { CALCULATE => \&loadCspecTag },
       UUID           => { CALCULATE => \&loadUUID }
      );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => undef
      );

} # sub BEGIN()


sub _init {
    my $self = shift;

    my ( $tag, $passwd, $gpath, $hpath, $hostname, @other ) = $self->rearrange(
	[ qw( TAG PASSWORD GPATH HPATH HOSTNAME ) ],
	@_ );

    Die( [ "Missing tag for ClearCase::Vob initialization" ] ) unless( $tag );
      
    $self->setPassword( $passwd ) if $passwd;
    $self->setGpath( $gpath ) if( $gpath );
    $self->setHpath( $hpath ) if( $hpath );
    $self->setHostname( $hostname ) if( $hostname );
    $self->setTag( $tag );
  }

sub new {
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self  = {};
    bless $self, $class;
    $self->_init( @_ );
    return $self;
} # new ()

sub loadName {
   my $self = shift;
   require File::Basename;
   return $self->setName( File::Basename::basename( $self->getTag() ) );
}

sub loadRootElement {
    my $self = shift;

    return $self->setRootElement( ClearCase::Element->new( -pathname => $self->getTag() . $OS::Common::Config::slash . '.@@' ) );
}

sub loadAllReplica {
    my $self = shift;

    ClearCase::lsreplica(
	-short => 1,
	-invob => $self->getTag()
	);
    my @reps = ClearCase::getOutput();
    grep chomp, @reps;
    my %replicas = ();
    foreach ( @reps ) {
	$replicas{ $_ } = ClearCase::Replica->new( -name => $_, -vob => $self );
    }
    return $self->setAllReplica( \%replicas );
}

sub loadMyReplica {
    my $self = shift;

    ClearCase::describe(
	-fmt => '"%[replica_name]p"',
	-argv => 'vob:' . $self->getTag()
	);
    my $rep = ClearCase::getOutputLine();
    chomp $rep;
    my %reps = %{ $self->getAllReplicas() };
    unless( defined $reps{ $rep } ) {
	$reps{ $rep } = ClearCase::Replica->new( -name => $rep, -vob => $self );
	$self->setAllReplicas( \%reps );
    }
    return $self->setMyReplica( $reps{ $rep } );
}

sub loadVob {
    my $self = shift;

    ClearCase::describe(
	-long => 1,
	-argv => 'vob:' . $self->getTag()
	);
    my @erg = ClearCase::getOutput();
    grep chomp, @erg;

    $self->setAdminVob( 0 );
    $self->setMyAdminVob( undef );
    foreach ( @erg ) {
	next if( $self->getAdminVob() == 1 and m/^\s*AdminVOB\s+<\-\s+/ ); # skip AdminVOB hyperlink lines, the vob has already been registered as Admin Vob
	if( m/^\s*VOB storage host:pathname\s+(\S+).*$/ ) {
	    my $tmp = $1;
	    $tmp =~ s/"//g;
	    $tmp =~ s/\'//g;
	    my ($h, $p) = split /:/, $tmp;
	    $self->setHostname( $h );
	    $self->setHpath( $p );
	} elsif( m/^\s*VOB storage global pathname\s+(\S+).*$/ ) {
	    my $tmp = $1;
	    $tmp =~ s/"//g;
	    $tmp =~ s/\'//g;
	    $self->setGpath( $tmp );
	} elsif( m/owner\s+(\S+).*/ ) {
	    $self->setOwner( $1 );
	} elsif( m/^\s*AdminVOB\s+<\-\s+/ ) {
	    $self->setAdminVob( 1 );
	} elsif( m/^\s*AdminVOB\s+\->\s+vob:(\S+).*$/ ) {
	    my $adminVob = $ClearCase::Common::Config::myHost->getRegion()->getVob( $1 );
	    $self->setMyAdminVob( $adminVob );
	}
    }
    return;
}

sub exists
  {
      my $self = shift;

      unless( defined $self->getExists() ) {
	  ClearCase::disableErrorOut();
	  ClearCase::disableDieOnErrors();
	  ClearCase::describe(
	      -argv => 'vob:' . $self->getTag(),
	      -short    => 1
	      );
	  my $ex = ( ClearCase::getRC() == 0 );
	  ClearCase::enableErrorOut();
	  ClearCase::enableDieOnErrors();
	  $self->setExists( $ex ) if( $ex );
	  return $ex;
      } else {
	  return $self->getExists();
      }
  }

sub mount
  {
      my $self = shift;

      ClearCase::mount( -tag => $self->getTag() );
      return ( ClearCase::getRC() == 0 );
  }

sub create
  {
      my $self = shift;
      if ( $self->exists() )
	{
	    Warn( [ 'Cannot create VOB ' . $self->getTag(), '. It already exists.' ] );
	    return $self;
	}
      my $public = 0;
      $public = 1 if defined $self->getPassword();
      ClearCase::mkvob(
	  -tag      => $self->getTag(),
	  -public   => $public,
	  -password => $self->getPassword(),
	  -hpath    => $self->getHpath(),
	  -gpath    => $self->getGpath(),
	  -host     => $self->getHostname()
	  );
      if( ClearCase::getRC() == 0 ) {
	  $self->setExists( 1 );
	  return $self;
      }
      return undef;
  }

sub typeCreationConfig {
    my $self = shift;

    # will return array @config
    # $config[0] = 1|0, 1 = create global type, 0 = create ordinary type
    # $config[1] = undef|ClearCase::Vob, the vob object is the root of a possibly existing administrative vob hierarchy
    my @config = ();
    my $GlobalAndAcquire = 0;
    my $targetVob = $self;
    $GlobalAndAcquire = 1 if( $self->getAdminVob() or $self->getMyAdminVob() );
    while( $targetVob->getMyAdminVob() ) {
	$targetVob = $self->getMyAdminVob();
    }
    $config[0] = $GlobalAndAcquire;
    $config[1] = $targetVob;
    return @config;
}

sub loadHyperlinkTypes {
   my $self = shift;

   # this subroutine will only be called once,
   # it initializes the attribute HyperlinkTypes
   # with a reference to an hash containing the hyperlink type objects,
   # for hyperlink types existed at time of subroutine execution.
   ClearCase::lstype(
      -short      => 1,
      -kind       => 'hltype',
      -invob      => $self->getTag() );

   my @hyperlinks = ClearCase::getOutput();
   grep( chomp, @hyperlinks );

   my %hltypes = ();
   foreach ( @hyperlinks ) {
       $hltypes{ $_ } = ClearCase::HlType->new( -name => "$_", -vob => $self );
   }
   return $self->setHyperlinkTypes( \%hltypes );
}

sub getHlType {
    my $self = shift;
    my $name = shift;

    my %tmp = %{ $self->getHyperlinkTypes() };
    return $tmp{ $name } if( defined $tmp{ $name } );
    my $hltype = ClearCase::HlType->new( -name => $name, -vob => $self );
    if( $hltype->exists() ) {
	$tmp{ $name } = $hltype;
	$self->setHyperlinkTypes( \%tmp );
	return $hltype;
    }
    return undef;
}

sub createHyperlinkType {
    my $self = shift;

    my ( $name, @other ) = $self->rearrange(
	[ qw( NAME ) ],
	@_ );

    my $hltype = $self->getHlType( $name );
    return $hltype if( $hltype );

    my %tmp = %{ $self->getHyperlinkTypes() };

    my @config = $self->typeCreationConfig();

    $hltype = ClearCase::HlType->new( -name => $name, -vob  => $config[1] );
    unless( $hltype->exists() ) {
	$hltype->create(
	    -global => $config[0],
	    -acquire => $config[0]
	    );
    }
    $tmp{ $name } = $hltype;
    $self->setHyperlinkTypes( \%tmp );
    return $hltype;
}

sub loadElementTypes {
   my $self = shift;

   # this subroutine will only be called once,
   # it initializes the attribute ElementTypes
   # with a reference to an hash containing the element type objects,
   # for element types existed at time of subroutine execution.
   ClearCase::lstype(
      -short      => 1,
      -kind       => 'eltype',
      -invob      => $self->getTag() );

   my @typenames = ClearCase::getOutput();
   grep( chomp, @typenames );

   my %types = ();
   foreach ( @typenames ) {
       $types{ $_ } = ClearCase::ElType->new( -name => "$_", -vob => $self );
   }
   return $self->setElementTypes( \%types );
}

sub loadTriggerTypes {
   my $self = shift;

   # this subroutine will only be called once,
   # it initializes the attribute TriggerTypes
   # with a reference to an hash containing the trigger type objects,
   # for trigger types existed at time of subroutine execution.
   ClearCase::lstype(
      -short      => 1,
      -kind       => 'trtype',
      -invob      => $self->getTag() );

   my @typenames = ClearCase::getOutput();
   grep( chomp, @typenames );


   my %types = ();
   foreach ( @typenames ) {
       $types{ $_ } = ClearCase::TrType->new( -name => "$_", -vob => $self );
   }
   return $self->setTriggerTypes( \%types );
}

sub loadLabelTypes {
    my $self = shift;

    # this subroutine will only be called once,
    # it initializes the attribute LabelTypes
    # with a reference to an empty hash.
    my %types = ();
    return $self->setLabelTypes( \%types );
}

sub getLbType {
    my $self = shift;
    my $name = shift;

    my %tmp = %{ $self->getLabelTypes() };
    return $tmp{ $name } if( defined $tmp{ $name } );
    my $lbtype = ClearCase::LbType->new( -name => $name, -vob => $self );
    if( $lbtype->exists() ) {
	$tmp{ $name } = $lbtype;
	$self->setLabelTypes( \%tmp );
	return $lbtype;
    }
    return undef;
}

sub createLabelType {
    my $self = shift;

    my ( $name, $pbranch, @other ) = $self->rearrange(
	[ qw( NAME PBRANCH ) ],
	@_ );

    my $lbtype = $self->getLbType( $name );
    return $lbtype if( $lbtype );

    if( $pbranch ) {
	$pbranch = 1;
    } else {
	$pbranch = 0;
    }
    my %tmp = %{ $self->getLabelTypes() };

    my @config = $self->typeCreationConfig();

    $lbtype = ClearCase::LbType->new( -name => $name, -vob => $config[1] );
    unless( $lbtype->exists() ) {
	$lbtype->create(
	    -pbranch => $pbranch,
	    -global  => $config[0],
	    -acquire => $config[0]
	    );
    }
    $tmp{ $name } = $lbtype;
    $self->setLabelTypes( \%tmp );
    return $lbtype;
}

sub loadBranchTypes {
    my $self = shift;

    # this subroutine will only be called once,
    # it initializes the attribute BranchTypes
    # with a reference to an empty hash.
    my %types = ();
    return $self->setBranchTypes( \%types );
}

sub getBrType {
    my $self = shift;
    my $name = shift;

    my %tmp = %{ $self->getBranchTypes() };
    return $tmp{ $name } if( defined $tmp{ $name } );
    my $brtype = ClearCase::BrType->new( -name => $name, -vob => $self );
    if( $brtype->exists() ) {
	$tmp{ $name } = $brtype;
	$self->setBranchTypes( \%tmp );
	return $brtype;
    }
    return undef;
}

sub createBranchType {
    my $self = shift;

    my ( $name, $pbranch, @other ) = $self->rearrange(
	[ qw( NAME PBRANCH ) ],
	@_ );

    my $brtype = $self->getBrType( $name );
    return $brtype if( $brtype );

    if( $pbranch ) {
	$pbranch = 1;
    } else {
	$pbranch = 0;
    }
    my %tmp = %{ $self->getBranchTypes() };

    my @config = $self->typeCreationConfig();

    $brtype = ClearCase::BrType->new( -name => $name, -vob => $config[1] );
    unless( $brtype->exists() ) {
	$brtype->create(
	    -pbranch => $pbranch,
	    -global  => $config[0],
	    -acquire => $config[0]
	    );
    }
    $tmp{ $name } = $brtype;
    $self->setBranchTypes( \%tmp );
    return $brtype;
}

sub loadFamilyID
  {
      my $self = shift;

      ClearCase::lsvob(
		       -long => 1,
                       -tag  => $self->getTag()
		      );
      my @erg = ClearCase::getOutput();
      grep chomp, @erg;
      @erg = grep m/family\s+uuid:/, @erg;
      $erg[0] =~ s/^.*\s+family\s+uuid:\s+(\S+).*/$1/;
      $self->setUUID( $erg[0] );
      $erg[0] =~ s/\.//g;
      $erg[0] =~ s/://g;
      $erg[0] = '[' . $erg[0] . ']';
      $self->setCspecTag( $erg[0] );
  }

sub loadCspecTag
  {
      my $self = shift;

      $self->loadFamilyID();
      return $self->getCspecTag();
  }

sub loadUUID
  {
      my $self = shift;

      $self->loadFamilyID();
      return $self->getUUID();
  }


sub load
  {
   my $proto = shift;
   my $class = ref ($proto) || $proto;
   my $path  = shift;

   ClearCase::disableErrorOut();
   ClearCase::disableDieOnErrors();
   my $tag = '';
   my $check = 0;
   if ( $path =~ m/^vobuuid:(\S+)/ )
     {
	 ClearCase::lsvob(
			  -family => $1,
			  -short  => 1
			 );
	 $check = 1  if( ClearCase::getRC() == 0 );
	 $tag = ClearCase::getOutputLine();
	 chomp $tag;
     }
   else
     {
	 ClearCase::describe(
			     -short => 1,
			     -argv => 'vob:' . $path
			    );
	 $check = 1 if( ClearCase::getRC() == 0 );
	 $tag = ClearCase::getOutputLine();
	 chomp $tag;
     }
   ClearCase::enableErrorOut();
   ClearCase::enableDieOnErrors();
   return $proto->new( -tag => $tag ) if( $check );
   return undef;
  }

1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2007 Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: uwe@satthoff.eu

=head1 SEE ALSO

=cut
