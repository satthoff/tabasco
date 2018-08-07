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

    my $branchType = ClearCase::BrType->new( -name => $self->getName(), -vob => $self->getVob()  );
    unless( $branchType->exist() )
    {
        $branchType->create();
    }
    ClearCase::mkbranch(
	-argv => $fve->getVXPN(),
	-name     => $self->getName(),
	-checkout => 0
	);
    ClearCase::describe(
	-argv => File::Basename::dirname( $fve->getVXPN() ),
	-fmt => '%On'
	);
    my $oid = ClearCase::getOutputLine();
    $self->setOid( $oid );
    return $self;
  }

sub loadMyElement {
    my $self = shift;

    return $self->setMyElement( ClearCase::Element->new( -pathname => $self->getVXPN() ) );
}

sub loadLatestVersion
  {
    my $self = shift;

    my $latestVersion = ClearCase::Version->new( -pathname => $self->getVXPN() . $OS::Common::Config::slash . 'LATEST' );
    return $self->setLatestVersion( $latestVersion );
  }

sub loadZeroVersion
  {
    my $self = shift;

    my $zeroVersion = ClearCase::Version->new( -pathname => $self->getVXPN() . $OS::Common::Config::slash . '0' );
    return $self->setZeroVersion( $zeroVersion );
  }

sub getLabeledVersion
  {
    my $self = shift;
    my $label = shift;

    my $labeledVersion = ClearCase::Version->new( -pathname => $self->getVXPN() . $OS::Common::Config::slash . $label );
    return $labeledVersion;
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
