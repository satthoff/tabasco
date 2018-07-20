package ClearCase::Version;

use strict;
use Carp;
use Log;

use File::Basename;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;
   require Data;
   require ClearCase::Common::CCPath;

   @ISA = qw(Exporter Data ClearCase::Common::CCPath);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   %DATA = (
       VersionString => undef,
       MyBranch => { CALCULATE => \&loadMyBranch },
       PreviousVersion => { CALCULATE => \&loadPreviousVersion }
       );

   Data::init(
       PACKAGE => __PACKAGE__,
       SUPER => 'ClearCase::Common::CCPath'
      );

} # sub BEGIN()

# constructor new is in ClearCase::Common::CCPath

sub _init {
    my $self = shift;
    
    my @tmp = split /\@\@/, $self->getVXPN();
    $self->setVersionString( $tmp[ $#tmp ] );
}


sub loadMyBranch {
    my $self = shift;

    my $branchPath = File::Basename::dirname( $self->getVXPN() );
    my $branch = ClearCase::InitBranch( -pathname => $branchPath );
    return $self->setMyBranch( $branch ) if( $branch );
    return undef;
}

sub loadPreviousVersion
  {
    my $self = shift;

    ClearCase::describe(
	-pathname => $self->getVXPN(),
	-fmt => '%PVn'
	);
    my $pv = ClearCase::getOutputLine();
    chomp $pv;
    return undef unless( $pv );
    my $pPath = $self->getMyBranch()->getMyElement()->getVXPN() . $pv;
    return $self->setPreviousVersion( $self->new( -pathname => $pPath ) );
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
