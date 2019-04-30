package OS::Command::ls;

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
	    Path      => undef,
            Short     => undef,
            Long      => undef,
            Directory => undef,
            All       => undef,
	    Host      => undef,
	    Slashdir  => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()

sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $short, $long, $dir, $all, $path, $host, $slash, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION SHORT LONG DIRECTORY ALL PATH HOST SLASHDIR ) ],
         @_ );
 #  confess join( ' ', @other ) if @other;

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setPath( $path );
   $self->setHost( $host ) if $host;
   $self->setShort( $short ) if $short;
   $self->setLong( $long ) if $long;
   $self->setDirectory( $dir ) if $dir;
   $self->setAll( $all ) if $all;
   $self->setSlashdir( $slash ) if $slash;

   return $self;
}

sub do_execute {
   my $self = shift;
   my @options = ();

   OS::Common::OsTool::registerRemoteHost( \@options, $self->getHost()->getHostname() ) if( $self->getHost() );
   push @options, '-1' if $self->getShort();
   push @options, '-l' if $self->getLong();
   push @options, '-d' if $self->getDirectory();
   push @options, '-a' if $self->getAll();
   push @options, '-p' if $self->getSlashdir();

   OS::Common::OsTool::ls( @options, $self->getPath() );
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
