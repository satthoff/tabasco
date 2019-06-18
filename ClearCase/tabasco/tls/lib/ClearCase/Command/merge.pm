package ClearCase::Command::merge;

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
      Nodata      => undef,
      FromVersion => undef,
      Topath      => undef,
      Graphical   => undef,
      Abort       => undef,
      Query       => undef,
      Qall        => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );


} # sub BEGIN()


sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $toPath, $fromVersion, $noData, $graphical, $abort, $query, $qall, @other ) =
      $class->rearrange(
         [ 'TRANSACTION', 'TOPATH', 'FROMVERSION', 'NODATA', 'GRAPHICAL', 'ABORT', 'QUERY', 'QALL' ],
         @_ );
   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction, $toPath );
   bless $self, $class;

   $self->setTopath($toPath);
   $self->setFromVersion($fromVersion);
   $self->setNodata($noData);
   $self->setGraphical($graphical);
   $self->setAbort($abort);
   $self->setQuery($query);
   $self->setQall($qall);
   return $self;
}

sub do_execute {
   my $self = shift;
   my @options = ();

   push @options, '-to ' . $self->getTopath()            if $self->getTopath();
   push @options, '-graphical'                           if $self->getGraphical();
   push @options, '-abort'                               if $self->getAbort();
   push @options, '-query'                               if $self->getQuery();
   push @options, '-qall'                                if $self->getQall();
   push @options, '-ndata'                               if $self->getNodata();
   push @options, '-version ' . $self->getFromVersion()  if $self->getFromVersion();


   my $old = $ClearCase::Common::Cleartool::DieOnErrors;
   $ClearCase::Common::Cleartool::DieOnErrors = 0;
   ClearCase::Common::Cleartool::disableErrorOut();

    ClearCase::Common::Cleartool::merge(
                                @options );

   $ClearCase::Common::Cleartool::DieOnErrors = $old;
   ClearCase::Common::Cleartool::enableErrorOut();

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
