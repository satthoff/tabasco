package OS::Common::Config;

use strict;
use Carp;
use File::Spec::Functions;
use Cwd;
use File::Basename;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
   $VERSION   = '0.99';
   require Exporter;

   @ISA = qw(Exporter);

   @EXPORT_OK = qw(
      VOB_BASE
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );
} # sub BEGIN()

use vars qw/
	    $trash $silent $slash $qslash $tempDir
	    $netPrefix $myHost/;


BEGIN {

    $trash  = '2>' . File::Spec::Functions::devnull();
    $silent = '1>' . File::Spec::Functions::devnull();
    $slash  = File::Spec::Functions::canonpath( '/' );
    $qslash = quotemeta( $slash );

    if ( $slash eq '/' )
    {
	$tempDir = '/tmp';
	$netPrefix = '/net';
    }
    else
    {
	$tempDir = $ENV{ TMP };
	$netPrefix = '\\';
    }
    
    my $hostname = `hostname`;
    chomp $hostname;
    require OS::Host;
    $myHost = OS::Host->new( -hostname => $hostname );
    
}

1;
