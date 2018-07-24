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
       RootElement => { CALCULATE => \&loadRootElement },
       Name         => { CALCULATE => \&loadName },
       Hostname  => { CALCULATE => \&loadVob },
       Owner        => { CALCULATE => \&loadVob },
       Hpath         => { CALCULATE => \&loadVob },
       Gpath         => { CALCULATE => \&loadVob },
       MyReplica   => { CALCULATE => \&loadMyReplica },
       AllReplica    => { CALCULATE => \&loadAllReplica },
       CspecTag   => { CALCULATE => \&loadCspecTag },
       UUID           => { CALCULATE => \&loadUUID },
       LabelTypes => { CALCULATE => \&loadLabelTypes },
       BranchTypes => { CALCULATE => \&loadBranchTypes }
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
    return $self->setAllReplica( \@reps );
}

sub loadMyReplica {
    my $self = shift;

    ClearCase::describe(
	-fmt => '"%[replica_name]p"',
	-pathname => 'vob:' . $self->getTag()
	);
    my $rep = ClearCase::getOutputLine();
    chomp $rep;
    return $self->setMyReplica( $rep );
}

sub loadVob {
    my $self = shift;

    ClearCase::describe(
	-long => 1,
	-pathname => 'vob:' . $self->getTag()
	);
    my @erg = ClearCase::getOutput();
    grep chomp, @erg;

    foreach ( @erg ) {
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
	      -pathname => 'vob:' . $self->getTag(),
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
	    Error( [ 'Cannot create VOB ' . $self->getTag(), '. It already exists.' ] );
	    return undef;
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

sub loadLabelTypes {
   my $self = shift;

   ClearCase::lstype(
      -short      => 1,
      -kind       => 'lbtype',
      -invob      => $self->getTag() );

   my @labels = ClearCase::getOutput();
   grep( chomp, @labels );

   my %lbtypes = ();
   foreach ( @labels ) {
       $lbtypes{ $_ } = ClearCase::LbType( -name => "$_", -vob => $self );
   }

   return setLabelTypes( \%lbtypes );
}

sub loadBranchTypes {
   my $self = shift;

   ClearCase::lstype(
      -short      => 1,
      -kind       => 'brtype',
      -invob      => $self->getTag() );

   my @branches = ClearCase::getOutput();
   grep( chomp, @branches );

   my %brtypes = ();
   foreach ( @branches ) {
       $brtypes{ $_ } = ClearCase::BrType( -name => "$_", -vob => $self );
   }

   return setBranchTypes( \%brtypes );
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
			     -pathname => 'vob:' . $path
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
