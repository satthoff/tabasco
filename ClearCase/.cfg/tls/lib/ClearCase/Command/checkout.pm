package ClearCase::Command::checkout;

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
       UndoList         => undef,
       IdenticalCheckin => 0,
       Argv => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()


sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $argv, $ident, @other ) =
      $class->rearrange(
         [ 'TRANSACTION', 'ARGV', 'IDENTICAL' ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setIdenticalCheckin( $ident );
   $self->setArgv( $argv );
   return $self;
}

sub do_execute {
   my $self = shift;
   ClearCase::Common::Cleartool::checkout(
      $self->getComment(),
      $self->getArgv() );

   my @undoList;
   my $co = $ClearCase::Common::Config::CC_CHECKOUT_OUTPUT;
   foreach( ClearCase::Common::Cleartool::getOutput() )
   {
      /^$co$/o && do {
         push @undoList, [ $1, $2 ];
      };
   }

   $self->setUndoList( \@undoList );
}

sub do_commit {
   my $self=shift;

   my @elements;
   foreach( reverse @{ $self->getUndoList() } )
   {
      my ( $element, $version ) = @$_;
      push ( @elements, $element . '@@' . $version );
   }

   my $option_ident = ($self->getIdenticalCheckin()) ? "-ident" : "";
   ClearCase::Common::Cleartool::checkin(
      "-nc $option_ident",
      @elements )
      if @elements;

}

sub do_rollback {
   my $self=shift;

   my @elements;
   foreach( reverse @{ $self->getUndoList() } )
   {
      my ( $element, $version ) = @$_;
      push ( @elements, $element . '@@' . $version );
   }

   ClearCase::Common::Cleartool::uncheckout( '-rm', @elements )
      if @elements;

}


1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2007, 2014  Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com


=head1 SEE ALSO

=cut
