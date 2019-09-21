package CLI::Config;

use strict;
use Carp;
use Getopt::Long;
use Cwd;
use File::Basename;
use OS::Common::Config;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $COPYRIGHT );
   $VERSION   = '201909-1';
   $COPYRIGHT = '(C) 2000 - 2019 Uwe Satthoff';
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
	    $baseDir %COMMAND_SHORTCUT %COMMAND
	    $location $myHome $mySelf $tmpWorkspace 
	    &comm/;


BEGIN {

    $baseDir = dirname ( Cwd::abs_path( dirname $0 ) );
    $myHome  = Cwd::abs_path( dirname $0 );
    $mySelf  = $myHome . $OS::Common::Config::slash . 'sdev';

    $location = $baseDir;
    $tmpWorkspace = '/tmp/tmpws';

require "CLI/Cmds.pl";
}
1;
