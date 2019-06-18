package OS::Command::mv;

use strict;
use Carp;
use Log;
use POSIX;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;

   @ISA = qw(Exporter Transaction::Command);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   %DATA = (
	    From   => undef,
	    To     => undef,
	    Host   => undef
	   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()

sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $to, $host, $from, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION TO HOST FROM ) ],
         @_ );
 #  confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setTo( $to );
   $self->setHost( $host );
   $self->setFrom( $from );

   return $self;
}

sub do_execute {
   my $self = shift;
   my @options = ();

   OS::Common::OsTool::disableErrorStop();
   OS::ls(
          -path      => $self->getTo(),
          -short     => 1,
          -directory => 1,
          -host      => $self->getHost()
         );
   OS::Common::OsTool::enableErrorStop();
   if( OS::Common::OsTool::getRC() == 0 )
     {
       Die( [ 'Cannot move path ' . $self->getFrom(),
	      'to target path ' . $self->getTo(),
	      'target path already exists.' ] );
     }
   OS::Common::OsTool::disableErrorStop();
   OS::ls(
          -path      => $self->getFrom(),
          -short     => 1,
          -directory => 1,
          -host      => $self->getHost()
         );
   OS::Common::OsTool::enableErrorStop();
   if( OS::Common::OsTool::getRC() != 0 )
     {
       Die( [ 'Cannot move path ' . $self->getFrom(),
	      'path does not exists.' ] );
     }
   my $to = $self->getTo();
   my $from = $self->getFrom();
   OS::Common::OsTool::registerRemoteHost( \@options, $self->getHost()->getHostname() ) if( $self->getHost() );
   push @options, $from;
   push @options, $to;
   OS::Common::OsTool::mv( @options );
}

sub do_commit {
   my $self = shift;
}

sub do_rollback {
   my $self = shift;
   my @options = ();

   OS::Common::OsTool::registerRemoteHost( \@options, $self->getHost()->getHostname() ) if( $self->getHost() );
   push @options, $self->getTo();
   push @options, $self->getFrom();
   OS::Common::OsTool::mv( @options );
}

1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2009  Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com

=head1 SEE ALSO

=cut
