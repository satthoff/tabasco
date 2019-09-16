package ClearCase::Vob;

use strict;
use Carp;
use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;
   require Data;

   @ISA = qw(Exporter Data ClearCase::Common::MetaObject);

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
       MyAdminVob => { CALCULATE => \&loadMyAdminVob },
       RootElement => { CALCULATE => \&loadRootElement },
       Hostname  => { CALCULATE => \&loadVob },
       Owner        => { CALCULATE => \&loadVob },
       Hpath         => { CALCULATE => \&loadVob },
       Gpath         => { CALCULATE => \&loadVob },
       MyReplica   => { CALCULATE => \&loadMyReplica },
       AllReplica    => { CALCULATE => \&loadAllReplica },
       CspecTag   => { CALCULATE => \&loadCspecTag },
       UUID           => { CALCULATE => \&loadUUID },
       ClientVobs => { CALCULATE => \&loadClientVobs },
       AdminVobHierarchyRoot => { CALCULATE => \&loadAdminVobHierarchyRoot }
      );

   Data::init(
      PACKAGE  => __PACKAGE__,
       SUPER    => 'ClearCase::Common::MetaObject'
      );

} # sub BEGIN()


sub _init {
    my $self = shift;

    my ( $tag, $passwd, $gpath, $hpath, $hostname, @other ) = $self->rearrange(
	[ qw( TAG PASSWORD GPATH HPATH HOSTNAME ) ],
	@_ );

    Die( [ "Missing tag for ClearCase::Vob initialization" ] ) unless( $tag );
    $tag =~ s/^vob://;

    $self->SUPER::_init( -type => 'vob', -name => $tag );
      
    $self->setPassword( $passwd ) if $passwd;
    $self->setGpath( $gpath ) if( $gpath );
    $self->setHpath( $hpath ) if( $hpath );
    $self->setHostname( $hostname ) if( $hostname );
    $self->setTag( $tag );
    return $self;
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
	-argv => $self->getFullName()
	);
    my $rep = ClearCase::getOutputLine();
    chomp $rep;
    my %reps = %{ $self->getAllReplica() };
    unless( defined $reps{ $rep } ) {
	$reps{ $rep } = ClearCase::Replica->new( -name => $rep, -vob => $self );
	$self->setAllReplica( \%reps );
    }
    return $self->setMyReplica( $reps{ $rep } );
}

sub loadVob {
    my $self = shift;

    my @erg = ();
    if( $self->{ 'description' } ) {
	@erg = @{ $self->{ 'description' } };
    } else {
	clearcase::describe(
	    -long => 1,
	    -argv => $self->getFullName()
	    );
	@erg = ClearCase::getOutput();
	grep chomp, @erg;
	$self->{ 'description' } = \@erg;
    }

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

sub exists {
    my $self = shift;

    unless( defined $self->getExists() ) {
	ClearCase::disableErrorOut();
	ClearCase::disableDieOnErrors();
	ClearCase::describe(
	    -argv => $self->getFullName(),
	    -short    => 1
	    );
	my $ex = ( ClearCase::getRC() == 0 );
	ClearCase::enableErrorOut();
	ClearCase::enableDieOnErrors();
	$self->setExists( $ex ) if( $ex );
	return $ex;
    }
    return $self->getExists();
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

      $self->loadFamilyID();  # the function $self->setCSpecTag() will be called in subroutine loadFamilyID()
      return $self->getCspecTag();
  }

sub loadUUID
  {
      my $self = shift;

      $self->loadFamilyID(); # the function $self->setUUID() will be called in subroutine loadFamilyID()
      return $self->getUUID();
  }


sub load {
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $path  = shift;

    ClearCase::disableErrorOut();
    ClearCase::disableDieOnErrors();
    my $tag = '';
    my $check = 0;
    if ( $path =~ m/^vobuuid:(\S+)/ ) {
	ClearCase::lsvob(
	    -family => $1,
	    -short  => 1
	    );
	$check = 1 if( ClearCase::getRC() == 0 );
	$tag = ClearCase::getOutputLine();
	chomp $tag;
    } else {
	$path =~ s/^vob://;
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

sub loadClientVobs {
    my $self = shift;

    my @results = $self->getToHyperlinkedObjects( ClearCase::HlType->new( -name => $ClearCase::Common::Config::adminVobLink, -vob => $self ) );
    my @adminClients = ();
    if( @results ) {
	foreach my $r ( @results ) {
	    push @adminClients, ClearCase::Vob->new( -tag => $r );
	}
	return $self->setClientVobs( \@adminClients );
    }
    return undef;
}

sub loadMyAdminVob {
    my $self = shift;

    my @results = $self->getFromHyperlinkedObjects( ClearCase::HlType->new( -name => $ClearCase::Common::Config::adminVobLink, -vob => $self ) );
    if( @results ) {
	return $self->setMyAdminVob( ClearCase::Vob->new( -tag => $results[0] ) );
    }
    return undef;
}

sub loadAdminVobHierarchyRoot {
    my $self = shift;

    my $adminVob = $self;
    while( $adminVob->getMyAdminVob() ) {
	$adminVob = $adminVob->getMyAdminVob();
    }
    return $self->setAdminVobHierarchyRoot( $adminVob );
}
1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2001, 2007 Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com

=head1 SEE ALSO

=cut
