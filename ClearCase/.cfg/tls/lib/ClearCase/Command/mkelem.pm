package ClearCase::Command::mkelem;

use strict;
use Carp;

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
      ElType      => undef,
      Comment     => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()



sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $element, $eltype, $comment, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION PATHNAME ELTYPE COMMENT) ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction, $element );
   bless $self, $class;

   $self->setElType( $eltype );
   $self->setComment( $comment );

   return $self;
}

sub do_execute {
   my $self = shift;
   my @options = ();

   if ( defined $self->getComment() )
   {
      push @options, ' -c "' . $self->getComment() . '"';
   }
   else
   {
      push @options, ' -nc';
   }

   push @options , '-eltype ' . $self->getElType()  if $self->getElType();

   ClearCase::Common::Cleartool::mkelem(
      @options,
      $self->getPathname() );
}

sub do_commit {
   my $self = shift;
   ClearCase::Common::Cleartool::checkin(
      '-nc',
      '-ident',
      $self->getPathname() );
}

sub do_rollback {
   my $self = shift;
   ClearCase::Common::Cleartool::checkin(
      '-nc',
      '-ident',
      $self->getPathname() );

   ClearCase::Common::Cleartool::rmelem(
      '-f',
      $self->getPathname() );

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
