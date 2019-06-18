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
       PreviousVersion => { CALCULATE => \&loadPreviousVersion },
       Labels => { CALCULATE => \&loadLabels }
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

sub attachLabel {
    my $self = shift;

    my ( $name, $replace, @other ) = $self->rearrange(
	[ 'NAME', 'REPLACE' ],
	@_ );
    confess @other if @other;

    if( $replace ) {
	$replace = 1;
    } else {
	$replace = 0;
    }

    my @labels = @{ $self->getLabels() };
    my $newLabel = ClearCase::Label->new(
	-name => $name,
	-version => $self,
	-replace => $replace,
	-alreadyattached => 0
	);
    return undef unless( $newLabel );
    
    push @labels, $newLabel;
    $self->setLabels( \@labels );
    return $newLabel;
}

sub loadLabels {
    my $self = shift;

    ClearCase::describe(
	-argv => $self->getVXPN(),
	-fmt => '%Nl'
	);
    my $l = ClearCase::getOutputLine();
    chomp $l;
    my @labelNames = split /\s+/, $l;

    my @labels = ();
    foreach my $n ( @labelNames ) {
	push @labels, ClearCase::Label->new(
	    -name => $n,
	    -version => $self,
	    -alreadyattached => 1
	    );
    }
    return $self->setLabels( \@labels );
}


sub loadMyBranch {
    my $self = shift;

    return $self->setMyBranch( ClearCase::Branch->new( -pathname => $self->getVXPN() ) );
}

sub loadPreviousVersion
  {
    my $self = shift;

    ClearCase::describe(
	-argv => $self->getVXPN(),
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

Address bug reports and comments to: satthoff@icloud.com

=head1 SEE ALSO

=cut
