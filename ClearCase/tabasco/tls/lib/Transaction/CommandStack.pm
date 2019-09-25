package Transaction::CommandStack;

use strict;
use Carp;

use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
   $VERSION = '0.01';
   require Exporter;
   require Data;

   @ISA = qw(Exporter);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );
} # sub BEGIN()


sub END {
    while ( Transaction::getTransaction() ) {
	Transaction::rollback();
    }
}

sub new()
{
   my $proto = shift;
   my $class = ref ($proto) || $proto;
   my $self  = {};
   bless $self, $class;

   Die("CommandStack::new() not allowed")
     if not defined $proto;

   my ( $comment ) = @_;

   # initialize
   $self->{'ACTIONS'}   = [];
   $self->{'COMMENT'}   = $comment;

   return $self;
} # new ()

sub getComment {
   return $_[0]->{'COMMENT'}; }

sub commit {
   my $self = shift;
   confess "Usage error" if @_;

   foreach my $action ( reverse @{$self->{'ACTIONS'}} )  {
      $action->commit();
   }
   return;
} # commit

sub register {
   my ( $self, $action ) = @_;
   push @{$self->{'ACTIONS'}}, $action;
   return;
} # register


sub rollback {
   my $self = shift;
   confess "Usage error" if @_;

   foreach my $action ( reverse @{$self->{'ACTIONS'}} )  {
      $action->rollback();
   }

   return;
} # rollback

1;

__END__

=head1 EXAMPLES

=head1 AUTHOR INFORMATION

 Copyright (C) 2007 Uwe Satthoff

=head1 BUGS

 Address bug reports and comments to:
   satthoff@icloud.com

=head1 SEE ALSO

=cut

# ============================================================================
