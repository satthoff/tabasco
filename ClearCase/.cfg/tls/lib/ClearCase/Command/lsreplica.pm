package ClearCase::Command::lsreplica;

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
      Short    => undef,
      Long     => undef,
      Siblings => undef,
      InVob    => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );


} # sub BEGIN()


sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $invob, $short, $long, $siblings, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION INVOB SHORT LONG SIBLINGS ) ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setShort($short);
   $self->setLong($long);
   $self->setInVob($invob);
   $self->setSiblings($siblings);

   return $self;
}

sub do_execute {
   my $self = shift;
   my @options = ();

   push @options, '-s'       if $self->getShort();
   push @options, '-l'       if $self->getLong();
   push @options, '-invob ' . $self->getInVob() if $self->getInVob();
   push @options, '-siblings' if $self->getSiblings();

   ClearCase::Common::Cleartool::lsreplica( @options );
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
