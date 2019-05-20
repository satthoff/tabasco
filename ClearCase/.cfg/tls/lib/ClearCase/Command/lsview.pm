package ClearCase::Command::lsview;

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
       Long     => undef,
       Short    => undef,
       ViewTag  => undef,
       Region   => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );


} # sub BEGIN()


sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $viewtag, $long, $short, $region, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION VIEWTAG LONG SHORT REGION ) ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setLong( $long );
   $self->setShort( $short );
   $self->setViewTag( $viewtag );
   $self->setRegion( $region );

   return $self;
}

sub do_execute {
   my $self = shift;
   my @options = ();

   push @options, '-long'              if $self->getLong();
   push @options, '-short'             if $self->getShort();
   push @options, '-reg ' . $self->getRegion() if $self->getRegion();
   push @options, $self->getViewTag()  if $self->getViewTag();

   ClearCase::Common::Cleartool::lsview( @options );
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
