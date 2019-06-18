package ClearCase::Command::ln;

use strict;
use Carp;
use File::Basename;
use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA );
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
      Base     => undef,
      Target   => undef,
      Symbolic => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()


sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $target, $base, $symbolic, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION TARGET BASE SYMBOLIC ) ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setTarget( $target );
   $self->setBase( $base );
   $self->setSymbolic( $symbolic );

   return $self;
}

sub do_execute {
   my $self = shift;
   my @options = ();

   push @options , '-s'       if $self->getSymbolic();

   my $oldpwd = ClearCase::Common::Cleartool::GetCwd();
   ClearCase::Common::Cleartool::ChDir( dirname( $self->getBase()));

   ClearCase::Common::Cleartool::ln(
      $self->getComment(),
      @options,
      $self->getTarget(),
      basename( $self->getBase()));

   ClearCase::Common::Cleartool::ChDir( $oldpwd);
}

sub do_commit {
}

sub do_rollback {
   my $self = shift;
   ClearCase::Common::Cleartool::rmname(
      '-f',
      $self->getBase());
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
