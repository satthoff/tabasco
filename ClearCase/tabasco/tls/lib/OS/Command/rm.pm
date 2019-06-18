package OS::Command::rm;

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
	    Path     => undef,
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

   my ( $transaction, $path, $host, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION PATH HOST ) ],
         @_ );
 #  confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setPath( $path );
   $self->setHost( $host );

   return $self;
}

sub do_execute {
   my $self = shift;

   # in fact, the removal of the entire subtree will be performed in the commit, means during
   # successfull finishing of the appropriate transaction
   OS::Common::OsTool::disableErrorStop();
   OS::ls(
          -path      => $self->getPath(),
          -short     => 1,
          -directory => 1,
          -host      => $self->getHost()
         );
   OS::Common::OsTool::enableErrorStop();
   $self->{ SAVEPATH } = undef;
   if( OS::Common::OsTool::getRC() == 0 )
     {
       $self->{ SAVEPATH } = $self->getPath() . '.' . time;
       if( -f "$self->{SAVEPATH}" )
	 {
	   my @options = ();
	   OS::Common::OsTool::registerRemoteHost( \@options, $self->getHost()->getHostname() ) if( $self->getHost() );
	   push @options, '-rf';
	   OS::Common::OsTool::rm( @options, $self->{ SAVEPATH } );
	 }
       OS::mv(
	      -from => $self->getPath(),
	      -to   => $self->{ SAVEPATH },
	      -host => $self->getHost()
	     );
     }
}

sub do_commit {
   my $self = shift;
   my @options = ();

   if( $self->{ SAVEPATH } )
     {
       OS::Common::OsTool::registerRemoteHost( \@options, $self->getHost()->getHostname() ) if( $self->getHost() );
       push @options, '-rf';
       OS::Common::OsTool::rm( @options, $self->{ SAVEPATH } );
     }
}

sub do_rollback {
   my $self = shift;

   # the rollback will be performed within the OS::mv command
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
