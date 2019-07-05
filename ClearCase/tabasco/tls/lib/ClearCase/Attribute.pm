package ClearCase::Attribute;

use strict;
use Carp;
use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;

   @ISA = qw(Exporter Data);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   %DATA = (
       To => undef,
       AtType => undef
      );

   require Data;
   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => undef
      );


} # sub BEGIN()

sub new
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self  = {};
    bless $self, $class;

    return $self->_init( @_ );
} # new ()

sub _init {
    my $self = shift;
    
    my ( $attype, $to, @other ) = $self->rearrange(
	[ 'ATTYPE', 'TO' ],
	@_ );

    $self->setTo( $to );
    $self->setAtType( $attype );
    return $self;
}  

sub create {
    my $self = shift;

    my $toId = undef;
    my $attypeName = $self->getAtType()->getName();

    if( $self->getTo()->isa( 'ClearCase::Common::CCPath' ) ) {
	$toId = $self->getTo()->getVXPN();
    } elsif( $self->getTo()->isa( 'ClearCase::Common::MetaObject' ) ) {
	$toId = $self->getTo()->getFullName();
    } else {
	Die( [ 'FATAL ERROR: wrong TO object type in ClearCase::Attribute::create()' ] );
    }

    ClearCase::mkattr(
	-attribute => $attypeName,
	-object => $toId
	);
    return $self if( ClearCase::getRC() == 0 );
    return undef;
}


1;

__END__

=head1 EXAMPLES

=head1 AUTHOR INFORMATION

 Copyright (C) 2007 Uwe Satthoff

=head1 BUGS

 Address bug reports and comments to:
   satthoff@icloud.com

=head1 SEE ALSO

=cut

##############################################################################

