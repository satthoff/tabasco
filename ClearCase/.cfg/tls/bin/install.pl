
use File::Basename;
use Cwd;

#
# execute this BEGIN block as the very first set of statements
# to define OS specific parameters and to include the lib
# directory to the Perl INC list.
use vars qw/
	    $trash $silent $slash $qslash $base $ccp_newline $tempDir
	    /;
my @INCL_LIB = ();
BEGIN {

  $ccp_newline = ""; # Clearprompt newline option
  $tempDir = "/tmp";
  $base = File::Basename::dirname ( Cwd::abs_path( dirname $0 ) );
  if ( defined $ENV{OS} )
    {
      $base =~ s/\//\\/g;
      $ccp_newline = '-newline';
      $tempDir = $ENV{TEMP};
      push @INCL_LIB, ( "$base", "$base\\lib" );
    }
  else
    {
      push @INCL_LIB, ( "$base", "$base/lib" );

      # inserted for VDI Linux at ASML
      push @INCL_LIB, '/home/usatthof/myPerl/lib/site_perl/5.8.4/x86_64-linux';
    }
  unshift @INC, @INCL_LIB;

  require ClearCase;
  require TaBasCo;
  require OS;
}

use Log;

Log::setVerbosity( "debug" );
Transaction::start( -comment => 'TaBasCo installation' );

# loading the main task the very first time means also
# that all initialization in the vob will be performed
my $mainTask = TaBasCo::Task->getMainTask();


# label the installation
ClearCase::mklabel(
		   -argv => $TaBasCo::Common::Config::myVob->getTag() . $OS::Common::Config::slash . $TaBasCo::Common::Config::toolRoot . $OS::Common::Config::slash . $TaBasCo::Common::Config::toolPath,
		   -label    => $TaBasCo::Common::Config::toolSelectLabel,
		   -recurse  => 1
		  );
ClearCase::mklabel(
                   -argv => $TaBasCo::Common::Config::myVob->getTag() . $OS::Common::Config::slash . $TaBasCo::Common::Config::toolRoot,
                   -label    => $TaBasCo::Common::Config::toolSelectLabel
                  );


# finaly create all trigger types
foreach my $trg ( keys %TaBasCo::Common::Config::allTrigger )
  {
    my $trt = ClearCase::TrType->new( -name => $trg, -vob => $TaBasCo::Common::Config::myVob );
    $trt->create(
                 -all     => $TaBasCo::Common::Config::allTrigger{ $trg }->{ 'all' },
                 -element => $TaBasCo::Common::Config::allTrigger{ $trg }->{ 'element' },
                 -execu   => '"' . $TaBasCo::Common::Config::allTrigger{ $trg }->{ 'execu' } . '"',
                 -execw   => '"' . $TaBasCo::Common::Config::allTrigger{ $trg }->{ 'execw' } . '"',
                 -command => $TaBasCo::Common::Config::allTrigger{ $trg }->{ 'ops' }
                );
    if( defined( $TaBasCo::Common::Config::allTrigger{ $trg }->{ 'att' } ) )
      {
        $trt->attach( TaBasCo::Common::Config::getConfigElement()->getVXPN() );
      }
  }

Transaction::commit(); # TaBasCo installation

# load the user interface
my $ui = TaBasCo::UI->new();

my $cf = TaBasCo::Common::Config::getConfigElement()->getNormalizedPath();
$ui->okMessage( "Installation finished.
You should now label your configuration
from where you want to start from with
the initial baseline.
Open the version tree browser for file
$cf
to see the name of the initial baseline.
At least the root directory of the Vob
has to be labeled.
And DO NOT label the imported $TaBasCo::Common::Config::toolRoot subtree !!! " );
