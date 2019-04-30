package ClearCase::Command::setview;

use strict;
use Carp;
use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
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

} # sub BEGIN()


use vars qw( %DATA );
%DATA = (
   Tag   => undef,
   Exec  => undef
);

Data::init(
   PACKAGE  => __PACKAGE__,
   SUPER    => 'Transaction::Command'
   );


sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;
   my $self  = $class->SUPER::new( @_ );
   bless $self, $class;

   my ( $tag ,$exec ) = $self->rearrange( [ qw( TAG EXEC ) ], @_ );
   $self->setTag(  $tag );
   $self->setExec(  $exec );

   return $self;
}

sub do_execute {
   my $self = shift;

   ClearCase::Common::Cleartool::setview(
      -exec    => $self->getExec(),
      $self->getTag()
   );
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
