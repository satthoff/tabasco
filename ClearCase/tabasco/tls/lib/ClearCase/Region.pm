package ClearCase::Region;

use strict;
use Carp;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;
   require Data;
   
   @ISA = qw(Exporter Data);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   %DATA = (
       Name => undef,
       Vobs => { CALCULATE => \&loadVobs },
       Views => { CALCULATE => \&loadViews }
       );

   Data::init(
      PACKAGE     => __PACKAGE__,
      SUPER       => 'Data'
      );
} # sub BEGIN()

sub new {
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self  = {};
    bless $self, $class;

    return $self->_init( @_ );
}

sub _init {
   my $self = shift;

    my ( $name, @other ) = $self->rearrange(
	[ 'NAME' ],
	@_ );
 #   confess "" if @other;
  
   return undef unless( $name );
   $self->setName( $name );
   return $self;
} # _init

sub loadVobs {
   my $self = shift;

   ClearCase::lsvob( -short => 1, -region => $self->getName() );
   my @erg = ClearCase::getOutput();
   grep chomp, @erg;

   my %vobs = ();
   foreach ( @erg ) {
       $vobs{ $_ } = ClearCase::Vob->new( -tag => $_ );
       $vobs{ $_ }->setExists( 1 );
   }
   return $self->setVobs( \%vobs );
}

sub loadViews {
   my $self = shift;

   ClearCase::lsview( -short => 1, -region => $self->getName() );
   my @erg = ClearCase::getOutput();
   grep chomp, @erg;

   my %views = ();
   foreach ( @erg ) {
       $views{ $_ } = ClearCase::View->new( $_ );
   }
   return $self->setViews( \%views );
}

sub getView {
    my $self = shift;
    my $tag = shift;

    my %tmp = %{ $self->getViews() };
    return $tmp{ $tag } if( defined $tmp{ $tag } );
    return undef;
}

sub getVob {
    my $self = shift;
    my $tag = shift;

    my %tmp = %{ $self->getVobs() };
    return $tmp{ $tag } if( defined $tmp{ $tag } );

    # the provided tag could be a valid pathname into the vob
    # or a full name with prefix vob:
    my $tryVob = ClearCase::Vob->load( -tag => $tag );
    if( $tryVob ) {
	$tag = $tryVob->getTag();
	return $tmp{ $tag } if( defined $tmp{ $tag } );
	$tmp{ $tag } = $tryVob;
	$self->setVobs( \%tmp );
	return $tmp{ $tag };
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

 Copyright (C) 2007  Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com

=head1 SEE ALSO

=cut
