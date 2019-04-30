package OS::Command::copy;

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
	    From     => undef,
	    To       => undef,
	    ToHost   => undef,
	    FromHost => undef
	   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()

sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $to, $tohost, $fromhost, $from, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION TO TOHOST FROMHOST FROM ) ],
         @_ );

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setTo( $to );
   $self->setToHost( $tohost );
   $self->setFromHost( $fromhost );
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
          -host      => $self->getToHost()
         );
   OS::Common::OsTool::enableErrorStop();
   if( OS::Common::OsTool::getRC() == 0 )
     {
       Die( [ 'Cannot copy path ' . $self->getFrom(),
	      'to target path ' . $self->getTo(),
	      'target path already exists.' ] );
     }
   my $to = $self->getTo();
   my $from = $self->getFrom();
   if( $self->getToHost() )
     {
       $to = $self->getToHost()->getHostname() . ':' . $to;
     }
   if( $self->getFromHost() )
     {
       $from = $self->getFromHost()->getHostname() . ':' . $from;
     }
   push @options, '-o LogLevel=quiet';
   push @options, $from;
   push @options, $to;
   OS::Common::OsTool::scp( @options );
}

sub do_commit {
   my $self = shift;
}

sub do_rollback {
   my $self = shift;
   my @options = ();

   OS::Common::OsTool::registerRemoteHost( \@options, $self->getToHost()->getHostname() ) if( $self->getToHost() );
   push @options, '-rf';
   OS::Common::OsTool::rm( @options, $self->getTo() );
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
