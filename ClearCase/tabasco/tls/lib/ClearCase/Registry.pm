package ClearCase::Registry;

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
       Regions => { CALCULATE => \&loadRegions }
       );

   Data::init(
      PACKAGE     => __PACKAGE__,
      SUPER       => 'OS::Host'
      );
} # sub BEGIN()


sub _init {
   my $self = shift;

   $self->SUPER::_init( @_ );

   return;
} # _init

sub loadRegions {
    my $self = shift;

    ClearCase::lsregion();
    my @result = ClearCase::getOutput();
    grep chomp, @result;

    my %regions = ();
    foreach ( @result ) {
	$regions{ $_ } = ClearCase::Region->new( -name => $_ );
    }

    return $self->setRegions( \%regions );
}

sub getRegion {
    my $self = shift;
    
    my ( $name, @other ) = $self->rearrange(
	[ 'NAME' ],
	@_ );
    return undef unless( $name );
    my %regs = %{ $self->getRegions() };
    return $regs{ $name } if( defined $regs{ $name } );
    return undef;
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
