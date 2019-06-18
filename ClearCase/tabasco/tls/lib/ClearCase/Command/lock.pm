package ClearCase::Command::lock;

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
      Obsolete  => undef,
      Object   => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()


sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $obs, $object, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION OBSOLETE OBJECT) ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setObject( $object );
   $self->setObsolete( $obs ) if ( $obs );

   return $self;
}

sub do_execute {
   my $self = shift;

   my @options = ();
   push @options, '-obsolete' if $self->getObsolete();
   ClearCase::Common::Cleartool::lock( @options,
      $self->getObject() );

}

sub do_commit {
   my $self = shift;
}

sub do_rollback {
   my $self = shift;

      ClearCase::Common::Cleartool::unlock(
         $self->getObject() );
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

When   sending   bug   reports,   please  provide   the   version   of
checkin.pm, the  version of Perl and  the name and version  of the
operating system you are using.


=head1 SEE ALSO

=cut
