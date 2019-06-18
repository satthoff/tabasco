package ClearCase::Command::rmattr;

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
      Attribut  => undef,
      Value     => undef,
      Object    => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()


sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $attr, $object, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION ATTRIBUTE OBJECT ) ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setAttribut( $attr );

   ClearCase::Common::Cleartool::describe(
         '-fmt ' . '"%[' . $attr . ']NSa"',
         $object );
   my $value = ClearCase::Common::Cleartool::getOutputLine();
   $value =~ s/'/\\'/g if (defined( $value ));
   $self->setValue( $value );
   $self->setObject( $object );

   return $self;
}

sub do_execute {
   my $self = shift;
#   my @options = ();

   ClearCase::Common::Cleartool::rmattr(
#      @options,
      $self->getAttribut(),
      $self->getObject()
      );
}

sub do_commit {
   my $self = shift;
}

sub do_rollback {
   my $self = shift;
   ClearCase::Common::Cleartool::mkattr(
      $self->getAttribut(),
      "'" . $self->getValue()    . "'",
      $self->getObject()
      );
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
