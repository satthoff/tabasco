package ClearCase::Command::rmlabel;

use strict;
use Carp;
use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;
   require Transaction::Command;

   @ISA = qw(Exporter Transaction::Command);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   %DATA = (
      Label     => undef,
      UndoList  => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()



sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $label, $element, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION LABEL PATHNAME ) ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction, $element );
   bless $self, $class;

   $self->setLabel( $label );

   return $self;
}

sub do_execute {
   my $self = shift;

   ClearCase::Common::Cleartool::rmlabel(
      $self->getComment(),
      $self->getLabel(),
      $self->getPathname() );

   my @undoList;
   my $regex = $ClearCase::Common::Config::CC_LBTYPE_OUTPUT{'REMOVE'};
   foreach( ClearCase::Common::Cleartool::getOutput() )
   {
      /^$regex$/o && do {
         push @undoList, [ $1, $2, $3 ];
      }
   }

   $self->setUndoList( \@undoList );
}

sub do_commit {
   my $self = shift;
}

sub do_rollback {
   my $self = shift;

   foreach( @{ $self->getUndoList() } )
   {
      my ( $label, $element, $version ) = @$_;

      ClearCase::Common::Cleartool::mklabel(
         '-nc',
         $self->getLabel(),
         $element . '@@' .$version );
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

Address bug reports and comments to: uwe@satthoff.eu


=head1 SEE ALSO

=cut
