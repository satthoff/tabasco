package OS::Command::gtar;

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
	    Directory  => undef,
	    File       => undef,
	    Background => undef,
	    Host       => undef,
	    Source     => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()

sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $dir, $file, $bg, $host, $source, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION DIRECTORY FILE BACKGROUND HOST SOURCE ) ],
         @_ );
#   confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setDirectory( $dir );
   $file =~ s/\.gz\s*$//;
   $self->setFile( $file  . '.gz');
   $self->setBackground( $bg );
   $self->setHost( $host );
   $self->setSource( $source );

   return $self;
}

sub do_execute {
   my $self = shift;

   my @options = ();
   OS::Common::OsTool::registerRemoteHost( \@options, $self->getHost()->getHostname() ) if( $self->getHost() );
   OS::Common::OsTool::registerBackground( \@options ) if( $self->getBackground() );
   push @options, '-czpB --ignore-command-error';
   push @options, '--directory=' . $self->getDirectory();
   my $source = ' .';
   $source = ' ' . $self->getSource() if $self->getSource();
   push @options, '-f ' . $self->getFile() . $source;
   OS::Common::OsTool::gtar( @options );
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
