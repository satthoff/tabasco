package OS::Command::softlink;

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
	    From => undef,
	    Host => undef,
	    To   => undef
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

   OS::Common::OsTool::registerRemoteHost( \@options, $self->getHost()->getHostname() ) if( $self->getHost() );
   OS::Common::OsTool::disableErrorStop();
   OS::ls(
          -path      => $self->getFrom(),
          -short     => 1,
          -directory => 1,
          -host      => $self->getHost()
         );
   OS::Common::OsTool::enableErrorStop();
   if( OS::Common::OsTool::getRC() == 0 )
     {
       Die( [ 'Cannot create softlink ' . $self->getFrom(),
	      'Path already exists.' ] );
     }
   push @options, '-s';
   OS::Common::OsTool::ln( @options, $self->getTo(), $self->getFrom() );

}

sub do_commit {
   my $self = shift;
}

sub do_rollback {
   my $self = shift;
   my @options = ();

   OS::Common::OsTool::registerRemoteHost( \@options, $self->getHost()->getHostname() ) if( $self->getHost() );
   push @options, '-f';
   OS::Common::OsTool::rm( @options, $self->getFrom() );
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
