package OS::Command::chmod;

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
	    Path       => undef,
	    Permission => undef,
	    Host       => undef
   );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'Transaction::Command'
      );

} # sub BEGIN()

sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my ( $transaction, $permission, $path, $host, @other ) =
      $class->rearrange(
         [ qw( TRANSACTION PERMISSION PATH HOST ) ],
         @_ );

   my $self  = $class->SUPER::new( $transaction );
   bless $self, $class;

   $self->setPath( $path );
   $self->setPermission( $permission );
   $self->setHost( $host ) if $host;

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
   my $oldPerm = $erg[0]; 
   $oldPerm =~ s/^(\S+)\s+.*/$1/;
   $oldPerm =~s/^d//;
   $self->{OLDPERM} = $oldPerm;
   my $perm = $self->getPermission();
   $perm =~ s/^d//;
   my $user = substr $perm, 0, 3;
   $user =~ s/\-//g;
   $perm = substr $perm, 3;
   my $group = substr $perm, 0, 3;
   $group =~ s/\-//g;
   $perm = substr $perm, 3;
   $perm =~ s/\-//g;
   push @options, "u=$user,g=$group,o=$perm";

   OS::Common::OsTool::chmod( @options, $self->getPath() );
}

sub do_commit {
   my $self = shift;
}

sub do_rollback {
   my $self = shift;
   my @options = ();

   OS::Common::OsTool::registerRemoteHost( \@options, $self->getHost()->getHostname() ) if( $self->getHost() );
   my $perm = $self->{OLDPERM};
   my $user = substr $perm, 0, 3;
   $user =~ s/\-//g;
   $perm = substr $perm, 3;
   my $group = substr $perm, 0, 3;
   $group =~ s/\-//g;
   $perm = substr $perm, 3;
   $perm =~ s/\-//g;
   push @options, "u=$user,g=$group,o=$perm";

   OS::Common::OsTool::chmod( @options, $self->getPath() );
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
