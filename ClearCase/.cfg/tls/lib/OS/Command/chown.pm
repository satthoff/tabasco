package OS::Command::chown;

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
	    Path  => undef,
	    Owner => undef,
	    Group => undef,
            Host  => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()

sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $owner, $group, $path, $host, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION OWNER GROUP PATH HOST ) ],
         @_ );

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setPath( $path );
   $self->setOwner( $owner );
   $self->setGroup( $group );
   $self->setHost( $host );

   return $self;
}

sub do_execute {
   my $self = shift;
   my @options = ();

   OS::Common::OsTool::registerRemoteHost( \@options, $self->getHost()->getHostname() ) if( $self->getHost() );
   OS::ls(
          -path => $self->getPath(),
          -long => 1,
          -all  => 1,
          -directory => 1,
          -host => $self->getHost()
         );
   my @erg = OS::Common::OsTool::getOutput();
   grep chomp, @erg;
   my @tmp = split /\s+/, $erg[0];
   $self->{USER} = $tmp[2];
   $self->{GROUP} = $tmp[3];
   push @options, $self->getOwner() . ':' . $self->getGroup();

   OS::Common::OsTool::chown( @options, $self->getPath() );
}

sub do_commit {
   my $self = shift;
}

sub do_rollback {
   my $self = shift;
   my @options = ();

   OS::Common::OsTool::registerRemoteHost( \@options, $self->getHost()->getHostname() ) if( $self->getHost() );

   my $user = $self->{USER};
   my $group = $self->{GROUP};
   push @options, $user . ':' .$group;

   OS::Common::OsTool::chown( @options, $self->getPath() );
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
