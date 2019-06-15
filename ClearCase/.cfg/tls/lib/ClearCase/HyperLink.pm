package ClearCase::HyperLink;

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
       From => undef,
       To => undef,
       HlType => undef
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
    
    my ( $hltype, $from, $to, @other ) = $self->rearrange(
	[ 'HLTYPE', 'FROM', 'TO' ],
	@_ );

    $self->setFrom( $from );
    $self->setTo( $to );
    $self->setHlType( $hltype );
    return $self;
}  

sub create {
    my $self = shift;

    my $fromId = undef;
    my $toId = undef;
    my $hltypeName = $self->getHlType()->getName();

    if( $self->getFrom()->isa( 'ClearCase::Common::CCPath' ) ) {
	$fromId = $self->getFrom()->getVXPN();
    } elsif( $self->getFrom()->isa( 'ClearCase::Common::MetaObject' ) ) {
	$fromId = $self->getFrom()->getFullName();
    } else {
	Die( [ 'FATAL ERROR: wrong FROM object type in ClearCase::HyperLink::create()' ] );
    }

    if( $self->getTo()->isa( 'ClearCase::Common::CCPath' ) ) {
	$toId = $self->getTo()->getVXPN();
    } elsif( $self->getTo()->isa( 'ClearCase::Common::MetaObject' ) ) {
	$toId = $self->getTo()->getFullName();
    } else {
	Die( [ 'FATAL ERROR: wrong TO object type in ClearCase::HyperLink::create()' ] );
    }

    ClearCase::mkhlink(
	-hltype => $hltypeName,
	-to => $toId,
	-from => $fromId
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

