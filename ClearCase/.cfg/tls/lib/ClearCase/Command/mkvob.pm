package ClearCase::Command::mkvob;

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
      Tag      => undef,
      Public   => undef,
      Password => undef,
      Hpath    => undef,
      Gpath    => undef,
      Host     => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );


} # sub BEGIN()


sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $tag, $public, $password, $hpath, $gpath, $host, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION TAG PUBLIC PASSWORD HPATH GPATH HOST ) ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setTag( $tag );
   $self->setPublic( $public );
   $self->setPassword( $password );
   $self->setHpath( $hpath );
   $self->setGpath( $gpath );
   $self->setHost( $host );

   return $self;
}

sub do_execute {
   my $self = shift;
   my @options = ();
   push @options, '-tag ' . $self->getTag();
   push @options, '-nc';
   push @options, '-public -password ' . $self->getPassword() if ( $self->getPublic() );
   push @options, '-host ' . $self->getHost();
   push @options, '-hpath ' . $self->getHpath();
   push @options, '-gpath ' . $self->getGpath();
   ClearCase::Common::Cleartool::mkvob(
			       @options,
			       $self->getHpath()
			      );
}

sub do_commit {
   my $self = shift;
}

sub do_rollback {
   my $self = shift;
   ClearCase::Common::Cleartool::rmvob(
      '-f',
      $self->getGpath() );
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
