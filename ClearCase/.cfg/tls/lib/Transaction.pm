package Transaction;

use strict;
use Carp;

use Transaction::CommandStack;
use Transaction::Command;
use Log;

sub BEGIN {
   # =========================================================================
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
   $VERSION = '0.01';
   require Exporter;
   @ISA = qw(Exporter);
   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

} # sub BEGIN()


# ============================================================================
# Description

=head1 NAME

ClearCase - <short description>

=head1 SYNOPSIS

B<Transaction.pm> [options]

=head1 DESCRIPTION

<long description>

=head1 USAGE

=head1 METHODS

=cut

my @transaction = undef;

sub commit {

   if ( !defined $transaction[0] )
   {
      return;
   }

   Debug( [ '',
	    'COMMIT transaction ' . '"' . $transaction[0]->getComment() . '"',
	    '**************************************************',
	    '' ] );
   my $trt = shift @transaction;
   $trt->commit();
   return;
} # commit

sub start {
   my ( $comment, @other ) = Data->rearrange(
      [ 'COMMENT' ],
      @_ );
   confess @other if @other;

   unshift @transaction, Transaction::CommandStack->new( $comment );
   Debug( [ '',
	    '**************************************************',
	    'START transaction ' . '"' . $transaction[0]->getComment() . '"',
	    '' ] );
   return;
} # start

sub getTransaction {
   return $transaction[0];
} # getTransaction

sub release {
   my ( $self ) = @_;

   Debug( [ '',
	    'RELEASE transaction ' . '"' . $transaction[0]->getComment() . '"',
	    '**************************************************',
	    '' ] );
   shift @transaction;
   return;
} # release

sub rollback {

   if ( !defined $transaction[0] )
   {
      return;
   }

   Debug( [ '',
	    'ROLLBACK transaction ' . '"' . $transaction[0]->getComment() . '"',
	    '**************************************************',
	    '' ] );

   my $trt = shift @transaction;
   $trt->rollback();
   return;
} # rollback


1;

__END__

=head1 EXAMPLES

=head1 AUTHOR INFORMATION

 Copyright (C) 2004 Uwe Satthoff

=head1 BUGS

 Address bug reports and comments to:
   satthoff@icloud.com

=head1 SEE ALSO

=cut
