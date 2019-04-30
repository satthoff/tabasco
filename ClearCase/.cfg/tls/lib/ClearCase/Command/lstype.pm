package ClearCase::Command::lstype;

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
      Short       => undef,
      Kind        => undef,
      Type        => undef,
      InVob       => undef
      );

   Data::init(
      PACKAGE     => __PACKAGE__,
      SUPER       => "Transaction::Command"
      );

} # sub BEGIN()

sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $short, $kind, $type, $invob, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION SHORT KIND TYPE INVOB ) ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setShort( $short );
   $self->setKind( $kind );
   $self->setType( $type );
   $self->setInVob( $invob );

   return $self;
}

sub do_execute {
   my $self = shift;
   my @options = ();

   push @options , '-s'                          if $self->getShort();
   push @options , '-invob ' . $self->getInVob() if $self->getInVob();

   my $element =
      defined $self->getType()
         ?  $self->getKind() . ':' . $self->getType()
         :  '-kind ' . $self->getKind();

   ClearCase::Common::Cleartool::lstype(
      @options,
      $element );
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
