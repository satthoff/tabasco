package ClearCase::Command::lspriv;

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
       Other => undef,
       Tag => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()



sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $tag, $other, @others ) =
      $class->rearrange(
         [  'TRANSACTION', 'TAG', 'OTHER' ],
         @_ );
   confess join( ' ', @others ) if @others;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setOther( $other ) if( $other );
   $self->setTag( $tag ) if( $tag );

   return $self;
}

sub do_execute {
   my $self = shift;
   my @options = ();

   push @options , '-tag ' . $self->getTag()  if $self->getTag();
   push @options , '-other' if $self->getOther();

   ClearCase::Common::Cleartool::lspriv(@options);
}

sub do_commit {
}

sub do_rollback {
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
