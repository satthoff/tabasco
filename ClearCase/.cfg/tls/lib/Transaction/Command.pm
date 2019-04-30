package Transaction::Command;

use strict;
use Carp;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;
   require Data;

   @ISA = qw(Exporter Data);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   %DATA = (
      _Transaction => undef
      );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => ""
      );

} # sub BEGIN()


sub new {
   my $proto = shift;
   my ( $transaction ) = @_;
   my $class = ref $proto || $proto;
   my $self  = {};
   bless $self, $class;

   $self->set('_Transaction', $transaction );

   return $self;
}

sub execute {
   my $self = shift;

   # the do_execute() of a sibling command package will be called,
   # but NOT the do_execute() inhere - this must be stopped with a fatal error = confess.
   my $rc =$self->do_execute( @_ );

   my $trt = Transaction::getTransaction();
   $trt->register( $self )
      if defined $trt;
}

sub do_execute {
   confess "Error: ",__PACKAGE__,'::do_execute() not implemented';
}

sub commit {
   my $self = shift;
   $self->do_commit( @_ );
}
sub do_commit {
   my $self = shift;
   confess "Error: ",ref $self,'::do_commit() not implemented';
}

sub rollback {
   my $self = shift;
   $self->do_rollback( @_ );
}

sub do_rollback {
   my $self = shift;
   confess "Error: ",ref $self,'::do_rollback() not implemented';
}

sub getComment {
   return "-c \'". $_[0]->get('_Transaction')->getComment() ."\'";
}

1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2004, 2017 Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com

=head1 SEE ALSO

=cut
