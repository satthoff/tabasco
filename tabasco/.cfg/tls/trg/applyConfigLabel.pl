# post checkin trigger to attach configuration label
use strict;

# execute this BEGIN block as the very first set of statements
# to define OS specific parameters and to include the lib
# directory to the Perl INC list.
use vars qw/
	    $trash $silent $slash $qslash $base $ccp_newline $tempDir
	    /;
my @INCL_LIB = ();
BEGIN {

  $base = "";
  $ccp_newline = ""; # Clearprompt newline option
  $tempDir = "/tmp";
  if ( defined $ENV{OS} )
    {
      # we are on a Windows platform
      $base = "\\\\view\\$ENV{CLEARCASE_VIEW_TAG}$ENV{CLEARCASE_VOB_PN}";
      push @INCL_LIB, ( "$base\\.cfg\\tls\\lib" );
      $ccp_newline = '-newline';
      $tempDir = $ENV{TEMP};
    }
  else
    {
      # we are on a UNIX platform
      $base = "//view/$ENV{CLEARCASE_VIEW_TAG}$ENV{CLEARCASE_VOB_PN}";
      push @INCL_LIB, ( "$base/.cfg/tls/lib" );

      # insert privately installed IPC::ChildSafe path for demonststration @ ASML
      #push @INCL_LIB, '/home/usatthof/myPerl/lib/site_perl/5.8.4/x86_64-linux';
      
      # insert lib path for CtCmd
      #push @INCL_LIB, '/sdev/user/lib/site_perl/5.8.4/x86_64-linux';

    }
  unshift @INC, @INCL_LIB;
}

use lib '/sdev/user/lib/site_perl';
use OS::Config;
use TaBasCo::Config;

my $vobPattern = quotemeta( $ENV{CLEARCASE_VOB_PN} );
my @path = split /$vobPattern/, $ENV{CLEARCASE_PN};
my $toolPattern = quotemeta( $OS::Config::slash . $TaBasCo::Config::toolRoot . $OS::Config::slash );
exit 0 if( $path[$#path] =~ m/^$toolPattern/ );

my $label = uc( $ENV{ CLEARCASE_BRTYPE } ) . $TaBasCo::Config::nextLabelExtension;
my $rc = system( "cleartool mklabel -repl $label $ENV{ CLEARCASE_PN } $OS::Config::silent $OS::Config::trash" );
exit $rc;

