package ClearCase::Command::lsvob;

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
       Long        => undef,
       Tag         => undef,
       Family      => undef,
       Region      => undef
      );

   Data::init(
      PACKAGE     => __PACKAGE__,
      SUPER       => "Transaction::Command"
      );

} # sub BEGIN()


sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $short, $long, $tag, $family, $region, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION SHORT LONG TAG FAMILY REGION ) ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setShort(1)    if $short;
   $self->setLong(1) if $long;
   $self->setTag( $tag ) if $tag;
   $self->setFamily( $family ) if $family;
   $self->setRegion( $region ) if $region;

   return $self;
}

sub do_execute {
   my $self = shift;
   my @options = ();

   push @options , '-s' if $self->getShort();
   push @options , '-l' if $self->getLong();
   push @options , '-reg ' . $self->getRegion() if $self->getRegion();
   push @options , '-family ' . $self->getFamily() if $self->getFamily();
   push @options , $self->getTag() if $self->getTag();

   ClearCase::Common::Cleartool::lsvob(
      @options );
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
