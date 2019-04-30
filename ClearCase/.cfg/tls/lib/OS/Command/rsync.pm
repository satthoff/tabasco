package OS::Command::rsync;

use strict;
use Carp;
use Log;

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
	    FromHost   => undef,
	    ToHost     => undef,
	    From       => undef,
	    To         => undef,
	    Background => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'OS::Command::Base'
      );

} # sub BEGIN()

sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $fromHost, $toHost, $from, $to, $background, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION FROMHOST TOHOST FROM TO BACKGROUND ) ],
         @_ );
 #  confess join( ' ', @other ) if @other;

   if( defined $fromHost and defined $toHost )
     {
       Die( [ 'rsync : error in arguments.', 'from or to host must be empty = localhost' ] );
     }
   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setFromHost( $fromHost ) if( defined $fromHost );
   $self->setToHost( $toHost ) if( defined $toHost );
   $self->setBackground( $background ) if( defined $background );
   $self->setFrom( $from );
   $self->setTo( $to );

   return $self;
}

sub do_execute {
   my $self = shift;

   my @options = ();
   OS::Common::OsTool::registerBackground( \@options ) if( $self->getBackground() );
   push @options, '-avzH -e "ssh -o LogLevel=quiet" --no-motd --delete';
   my $fromPrefix = '';
   my $toPrefix   = '';
   $fromPrefix = $self->getFromHost()->getHostname() . ':' if( $self->getFromHost() );
   $toPrefix   = $self->getToHost()->getHostname() . ':' if( $self->getToHost );
   OS::Common::OsTool::rsync( @options, $fromPrefix . $self->getFrom(), $toPrefix . $self->getTo() );
}

sub do_commit {
   my $self = shift;
}

sub do_rollback {
   my $self = shift;
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
