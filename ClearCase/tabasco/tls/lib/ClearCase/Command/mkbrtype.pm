package ClearCase::Command::mkbrtype;

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
       Name     => undef,
       Vob      => undef,
       PBranch  => undef,
       Global   => undef,
       Acquire  => undef,
       Comment  => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()


sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $name, $vob, $pbranch, $global, $acquire, $comment, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION NAME VOB PBRANCH GLOBAL ACQUIRE COMMENT) ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;


   $self->setVob( $vob );
   $self->setName( $name );
   $self->setPBranch( $pbranch );
   $self->setGlobal( $global );
   $self->setAcquire( $acquire );
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

   push @options, '-pbranch' if $self->getPBranch();
   push @options, '-global' if $self->getGlobal();
   push @options, '-acquire' if $self->getAcquire();

   ClearCase::Common::Cleartool::mkbrtype(
      @options,
      $self->getName() . '@' . $self->getVob() );
}

sub do_commit {
   my $self = shift;
}

sub do_rollback {
   my $self = shift;
   ClearCase::Common::Cleartool::rmtype(
      '-f',
      '-rmall',
      'brtype:'. $self->getName() . '@' . $self->getVob() );
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
