
use File::Basename;
use Cwd;

#
# execute this BEGIN block as the very first set of statements
# to define OS specific parameters and to include the lib
# directory to the Perl INC list.
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

# declare all hyperlink types
foreach my $hltypeName ( @TaBasCo::Common::Config::allHlTypes ) {
    my $newType = ClearCase::HlType->new( -name => $hltypeName );
    $newType->create() unless( $newType->exists() );
}

# declare all label types
foreach my $lbtypeName ( @TaBasCo::Common::Config::allLbTypes ) {
    my $newType = ClearCase::LbType->new( -name => $lbtypeName );
    $newType->create() unless( $newType->exists() );
}

# declare all trigger types
foreach my $trtypeName ( @TaBasCo::Common::Config::allTrTypes ) {
    my $newType = ClearCase::TrType->new( -name => $trtypeName );
    $newType->create() unless( $newType->exists() );
}

# initialize the main task - based on the default ClearCase branch type 'main'
# the main task gets attached the root path of the installation Vob and
# of all sibling Vobs if the installation Vob is an admin Vob
my $mainTask = TaBasCo::Task::initializeMainTask( $TaBasCo::Common::Config::initialTaBasCoBaseline );
$mainTask->getFloatingRelease()->ensureAsFullRelease();
my $firstMainRelease = $mainTask->createNewRelease();

# create the task tabasco to manage the installed tool within its own task
# STILL MISSING: specify the installation root path as the only path of the tabasco task
my $tabascoTask = TaBasCo::Task->new( -name => 'tabasco' );
$tabascoTask->create( -baseline => $firstMainRelease );
$tabascoTask->getFloatingRelease()->ensureAsFullRelease();
$tabascoTask->createNewRelease();

Transaction::commit(); # TaBasCo installation

# load the user interface
my $ui = TaBasCo::UI->new();

my $cf = TaBasCo::Common::Config::getConfigElement()->getNormalizedPath();
$ui->okMessage( "Installation finished.

" );
