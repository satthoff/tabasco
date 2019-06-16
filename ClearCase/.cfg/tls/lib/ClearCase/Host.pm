package ClearCase::Host;

use strict;
use Carp;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;
   require Data;
   require OS::Host;

   @ISA = qw(Exporter Data OS::Host);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   %DATA = (
       Region => { CALCULATE => \&loadRegion },
       RegionName => { CALCULATE => \&loadHostinfo },
       Registry => { CALCULATE => \&loadHostinfo },
       CCVersion => { CALCULATE => \&loadHostinfo },
       OS => { CALCULATE => \&loadHostinfo },
       LicenseHost => { CALCULATE => \&loadHostinfo },
       CurrentView => { CALCULATE => \&loadCurrentView }
       );

   Data::init(
      PACKAGE     => __PACKAGE__,
      SUPER       => 'OS::Host'
      );
} # sub BEGIN()


sub loadHostinfo {
    my $self = shift;

    ClearCase::hostinfo(
	-hostname => $self->getHostname(),
	-long => 1
	);
    my @result = ClearCase::getOutput();
    grep chomp, @result;
    foreach my $line ( @result ) {
	next if( $line =~ m/^Client:/ );
	if( $line =~ m/^\s+Operating system:\s+(\S+)\.*$/ ) {
	    $self->setOS( $1 );
	} elsif( $line =~ m/^\s+Registry host:\s+(\S+)\.*$/ ) {
	    $self->setRegistry( ClearCase::Registry->new( -hostname => $1 ) );
	} elsif( $line =~ m/^\s+License host:\s+(\S+)\.*$/ ) {
	    $self->setLicenseHost( OS::Host->new( -hostname => $1 ) );
	} elsif( $line =~ m/^\s+Registry region:\s+(\S+)\.*$/ ) {
	    $self->setRegionName( $1 );
	}
    }
    return;
}

sub loadRegion {
    my $self = shift;

    return $self->setRegion( $self->getRegistry()->getRegion( $self->getRegionName() ) );
}

sub loadCurrentView {
    my $self = shift;
    
    require ClearCase::View;
    ClearCase::pwv( -short => 1 );
    my $tag = ClearCase::getOutputLine();
    chomp $tag;
    if( defined $tag and $tag !~ m/NONE/ ) {
        return $self->setCurrentView( $self->getRegion()->getView( $tag ) );
    } else {
        return undef;
    }
}


1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2009 2013  Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com

=head1 SEE ALSO

=cut
