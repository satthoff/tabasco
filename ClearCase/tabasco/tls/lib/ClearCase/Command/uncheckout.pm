package ClearCase::Command::uncheckout;

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
      UndoList       => undef,
      Keep           => undef,
      Rm             => undef,
      Argv           => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()


sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $argv, $rm, $keep, @other ) =
      $class->rearrange(
         [ 'TRANSACTION', 'ARGV', 'RM', 'KEEP' ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setKeep( $keep );
   $self->setRm( $rm );
   $self->setArgv($argv);

   return $self;
}

sub do_execute {
   my $self = shift;
   ClearCase::Common::Cleartool::uncheckout(
      '-keep',
      $self->getArgv() );

   my @undoList;
   my $unco = $ClearCase::Common::Config::CC_UNCHECKOUT_OUTPUT{'UNCO'};
   my $keep = $ClearCase::Common::Config::CC_UNCHECKOUT_OUTPUT{'KEEP'};

   foreach( ClearCase::Common::Cleartool::getOutput() )
   {
      # AFAIK the message from cleartool comes in the following order
      #
      #   Private version of "hw.c" saved in "hw.c.keep".
      #   Checkout cancelled for "hw.c".
      #
      # We remeber them in this order, and undo them in opposite direction
      /^$unco$/o && do {
         push @undoList, [ 'UNCO' , $1 ];
      };
      /^$keep$/o && do {
         push @undoList, [ 'KEEP', $1, $2 ];
      };
   }

   $self->setUndoList( \@undoList );
}

sub do_commit {
   my $self=shift;

   my @keepfiles;
   foreach( reverse @{ $self->getUndoList() } )
   {
      if( $_->[0] eq 'KEEP' )
      {
         push @keepfiles, $_->[2];
      }
   }
   ClearCase::Common::Cleartool::execute( 'rm', '-f', @keepfiles );
}

sub do_rollback {
   my $self=shift;

   my @uncofiles;
   foreach( reverse @{ $self->getUndoList() } )
   {
      if( $_->[0] eq 'UNCO' )
      {
         push @uncofiles, $_->[1];
      }

   }

   ClearCase::Common::Cleartool::checkout( '-nc', @uncofiles );

   foreach( reverse @{ $self->getUndoList() } )
   {
      if( $_->[0] eq 'KEEP' )
      {
         ClearCase::Common::Cleartool::execute( 'mv', $_->[2], $_->[1] );
      }
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
