package ClearCase::Command::rmhlink;

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
      From      => undef,
      To        => undef,
      HlType    => undef,
      HLink     => undef,
      Comment   => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()


sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $from, $to, $hlink, $comment, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION FROM TO HLINK COMMENT) ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setFrom( $from );
   $self->setTo( $to );
   $self->setHLink( $hlink );
   $self->setComment( $comment );
   my @hlStrings = split(/\@/, $hlink);
   $self->setHlType( $hlStrings[0] );

   return $self;
}

sub do_execute {
   my $self = shift;
   my @options;

   if ( defined $self->getComment() )
   {
      push @options, ' -c "' . $self->getComment() . '"';
   }
   else
   {
      push @options, ' -nc';
   }

   ClearCase::Common::Cleartool::rmhlink(
      @options,
      $self->getHLink() );

}

sub do_commit {
   my $self = shift;
}

sub do_rollback {
   my $self = shift;

   my @options;

   if ( defined $self->getComment() )
   {
      push @options, ' -c "rolled-back:' . $self->getComment() . '"';
   }
   else
   {
      push @options, ' -nc';
   }

   ClearCase::Common::Cleartool::mkhlink(
      @options,
      $self->getHlType(),
      $self->getFrom(),
      $self->getTo() );
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
