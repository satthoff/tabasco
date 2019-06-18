package OS::Path;

use strict;
use Carp;
use File::Basename;
use Log;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;
   require Data;

   @ISA = qw(Exporter Data);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   %DATA = (
	    Pathname => undef,
            Host     => undef
	   );

   Data::init(
      PACKAGE     => __PACKAGE__,
      SUPER       => ''
      );
} # sub BEGIN()

sub new()
{
   my $proto = shift;
   my $class = ref ($proto) || $proto;
   my $self  = {};
   bless $self, $class;

   # initialize
   $self->_init( @_ );

   return $self;
} # new ()

sub _init {
  my $self = shift;

  my ( $pathname, $host, @other ) = $self->rearrange(
					  [ 'PATH', 'HOST' ],
						 @_ );
  unless( $host )
    {
      Die( [ 'No host specified for new Path object.' ] );
    }
  unless( $pathname )
    {
      Die( [ 'No pathname specified for new Path object.' ] );
    }
  $self->setPathname( $pathname );
  $self->setHost( $host );
  return;
} # _init

sub exist
  {
    my $self = shift;

    OS::disableErrorStop();
    OS::ls(
	   -path      => $self->getPathname(),
	   -short     => 1,
	   -directory => 1,
	   -all       => 1,
	   -host      => $self->getHost()->_getExecHost()
	  );
    OS::enableErrorStop();
    return ( OS::getRC() == 0 );
  }

sub list
  {
    my $self = shift;

    OS::disableErrorStop();
    OS::ls(
	   -path      => $self->getPathname(),
	   -short     => 1,
	   -host      => $self->getHost()->_getExecHost()
	  );
    OS::enableErrorStop();
    if( OS::getRC() == 0 )
      {
	my @tmp = OS::getOutput();
	grep chomp, @tmp;
	return \@tmp;
      }
    return undef;
  }

sub changeOwnership
  {
    my $self = shift;

    my ( $user, $group, @other ) = $self->rearrange(
						    [ 'OWNER', 'GROUP' ],
						    @_ );
    OS::chown(
	      -path  => $self->getPathname(),
	      -owner => $user,
	      -group => $group,
	      -host  => $self->getHost()->_getExecHost()
	     );
  }

sub changePermission
  {
    my $self = shift;

    my ( $permission, @other ) = $self->rearrange(
						  [ 'PERMISSION' ],
						  @_ );

    OS::chmod(
	      -path       => $self->getPathname(),
	      -permission => $permission,
              -host       => $self->getHost()->_getExecHost()
	     );
  }

sub createDirectory
  {
    my $self = shift;

    OS::mkdir(
	      -path => $self->getPathname(),
	      -host => $self->getHost()->_getExecHost()
	     );
  }

sub remove
{
   my $self = shift;

    OS::rm(
	      -path => $self->getPathname(),
	      -host => $self->getHost()->_getExecHost()
	     );
}

sub copy
{
   my $self = shift;

   my ( $fromPath, $toPath, @other ) = $self->rearrange(
						  [ 'FROMPATH', 'TOPATH' ],
						  @_ );
   if( $fromPath and $toPath )
   {
     Die( [ 'OS::Path::copy cannot accept from and to path. Coding error!' ] );
   }
   if( $fromPath )
   {
      OS::copy(
               -from     => $fromPath->getPathname(),
               -to       => $self->getPathname(),
               -tohost   => $self->getHost()->_getExecHost(),
               -fromhost => $fromPath->getHost()->_getExecHost()
              );
   }
   elsif( $toPath )
   {
      OS::copy(
               -from     => $self->getPathname(),
               -to       => $toPath->getPathname(),
               -tohost   => $toPath->getHost()->_getExecHost(),
               -fromhost => $self->getHost()->_getExecHost()
              );
   }
}

1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2009 Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com

=head1 SEE ALSO

=cut
