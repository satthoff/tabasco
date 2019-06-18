package ClearCase::Command::rmtrigger;

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
      Trigger => undef,
      Element => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()

sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $trg, $elem, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION TRIGGER ELEMENT ) ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setTrigger( $trg );
   $self->setElement( $elem );

   return $self;
}

sub do_execute {
   my $self = shift;
   my @options = ();

   ClearCase::Common::Cleartool::rmtrigger(
      $self->getTrigger(), $self->getElement()
      );
}

sub do_commit {
   my $self = shift;
}

sub do_rollback {
   my $self = shift;
   ClearCase::Common::Cleartool::mktrigger(
      $self->getTrigger(),
      $self->getElement()
      );
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

Address bug reports and comments to: satthoff@icloud.com

=head1 SEE ALSO

=cut
