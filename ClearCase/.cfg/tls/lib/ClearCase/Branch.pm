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
    my $self = shift;
    my ( $name, $fve, @other ) = $self->rearrange(
	[ 'NAME', 'FROMVERSION' ],
	@_ );

    my $branchType = ClearCase::BrType->new( -name => $name, -vob => $fve->getVob()  );
    unless( $branchType->exists() )
    {
        $branchType->create();
    }
    ClearCase::mkbranch(
	-argv => $fve->getVXPN(),
	-branchtype => $branchType,
	-checkout => 0
	);
    my $newBranch = $self->new( -pathname => File::Basename::dirname( $fve->getVXPN() ) . $OS::Common::Config::slash . $name );
    return $newBranch; # it should be a TaBasCo::Task as well, because $self is a Task
  }

sub loadMyElement {
    my $self = shift;

    return $self->setMyElement( ClearCase::Element->new( -pathname => $self->getVXPN() ) );
}

sub getLatestVersion
  {
    my $self = shift;

    my $latestVersion = ClearCase::Version->new( -pathname => $self->getVXPN() . $OS::Common::Config::slash . 'LATEST' );
    return $latestVersion;
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

Address bug reports and comments to: satthoff@icloud.com


=head1 SEE ALSO

=cut
