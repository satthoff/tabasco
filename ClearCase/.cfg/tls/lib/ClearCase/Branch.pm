package ClearCase::Branch;

use strict;
use Carp;
use File::Basename;

use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;
   require Data;
   require ClearCase::Common::CCPath;

   @ISA = qw(  Exporter Data ClearCase::Common::CCPath );

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );


   %DATA = (
       BranchString => undef,
       CspecPath => { CALCULATE => \&loadCspecPath }
       Name => undef,
       MyElement => { CALCULATE => \&loadMyElement },
       LatestVersion => { CALCULATE => \&loadLatestVersion },
       ZeroVersion   => { CALCULATE => \&loadZeroVersion }
       );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => "ClearCase::Common::CCPath"
      );


} # sub BEGIN()

# constructor new is in ClearCase::Common::CCPath

sub _init {
    my $self = shift;
    $self->setName( File::Basename::basename( $self->getVXPN() ) );
}

sub create {
    # must be moved to ClearCase::Element and renamed to createBranch
    my $self = shift;
    my ( $fve, @other ) = $self->rearrange(
	[ 'FROMVERSION' ],
	@_ );

    my $branchType = ClearCase::InitBrType( -name => $self->getName(), -vob => $self->getVob()  );
    unless( $branchType->exist() )
    {
        $branchType->create();
    }
    ClearCase::mkbranch(
	-pathname => $fve->getVXPN(),
	-name     => $self->getName(),
	-checkout => 0
	);
    ClearCase::describe(
	-pathname => File::Basename::dirname( $fve->getVXPN() ),
	-fmt => '%On'
	);
    my $oid = ClearCase::getOutputLine();
    $self->setOid( $oid );
    return $self;
  }

sub loadMyElement {
    my $self = shift;

    my @tmp = split /\@\@/, $self->getVXPN();
    pop @tmp;
    my $ePath = join '@@', @tmp;
    $ePath =~ s/$/\@\@/ unless( $ePath =~ m/\@\@$/ );
    return $self->setMyElement( ClearCase::InitElement( -pathname => $ePath ) );
}

sub loadLatestVersion
  {
    my $self = shift;

    my $latestVersion = ClearCase::InitVersion( -pathname => $self->getVXPN() . $OS::Config::slash . 'LATEST' );
    return $self->setLatestVersion( $latestVersion );
  }

sub loadZeroVersion
  {
    my $self = shift;

    my $zeroVersion = ClearCase::InitVersion( -pathname => $self->getVXPN() . $OS::Config::slash . '0' );
    return $self->setZeroVersion( $zeroVersion );
  }

sub getLabeledVersion
  {
    my $self = shift;
    my $label = shift;

    my $labeledVersion = ClearCase::InitVersion( -pathname => $self->getVXPN() . $OS::Config::slash . $label );
    return $labeledVersion;
  }

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

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2010  Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: uwe@satthoff.eu


=head1 SEE ALSO

=cut
