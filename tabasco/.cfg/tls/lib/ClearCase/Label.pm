package ClearCase::Label;

use strict;
use Carp;

use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;

   @ISA = qw(  Exporter Data );

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   require Data;

   %DATA = (
            Label         => undef,
	    Configuration => undef
	   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => ""
      );


} # sub BEGIN()

sub new
{
   my $proto = shift;
   my $class = ref ($proto) || $proto;
   my $self  = {};
   bless $self, $class;

   $self->init(@_);

   return $self;
 }

sub create
  {
    my $self = shift;

    my ( $attach, $pbranch ) = $self->rearrange(
                                    [ qw( ATTACH PBRANCH ) ],
                                      @_ );

    my $lb = $self->getLabel();
    my $labelType = ClearCase::Type::LbType->new( $self->getLabel(), $self->getConfiguration()->getVob() );
    unless( $labelType->exist() )
      {
        my $perBranch = 0;
        $perBranch = $pbranch if( $pbranch );
        $labelType->create( -pbranch => $perBranch );
      }
    my $attachLabel = 1;
    $attachLabel = 0 unless( $attach );
    if( $attachLabel == 1 )
      {
        $self->getConfiguration()->mklabel(
                                       -name    => $self->getLabel()
                                      );
      }
    return $self;
  }

sub rename
  {
    my $self = shift;

    my ( $name ) = $self->rearrange(
                                    [ qw( NAME ) ],
                                      @_ );

    my $labelType = ClearCase::Type::LbType->new( $self->getLabel(), $self->getConfiguration()->getVob() );
    $labelType->rename( $name );
    $self->setLabel( $name );
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
