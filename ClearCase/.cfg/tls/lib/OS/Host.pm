package OS::Host;

use strict;
use Carp;

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
	    Hostname     => undef
#	    Zpools          => { CALCULATE => \&loadZpools }
	   );

   Data::init(
      PACKAGE     => __PACKAGE__,
      SUPER       => 'Data'
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

   my ( $hostname, @other ) = $self->rearrange(
         [ 'HOSTNAME' ],
       @_ );
   
   $self->setHostname( $hostname );
   return $self;
} # _init

sub _getExecHost
  {
    my $self = shift;

    my $execHost = undef;
    if( $OS::Common::Config::myHost->getHostname() ne $self->getHostname() )
      {
	$execHost = $self;
      }
    return $execHost;
  }

sub Path
  {
    my $self = shift;

    return OS::Path->new( @_, -host => $self );
  }

sub gmtTimeString
  {
    my $self = shift;

    my @gmt = gmtime();
    my @month = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    my $year = $gmt[5] + 1900;
    my $timeString = sprintf( "%s.%s.%s-GMT-%d.%d.%d", $gmt[3], $month[ $gmt[4] ], $year, $gmt[2], $gmt[1], $gmt[0]);
    return $timeString;
}

1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2009 2013  Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com

=head1 SEE ALSO

=cut
