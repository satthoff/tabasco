
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
}

use ClearCase;
use TaBasCo;
use OS;
use Log;

sub allVobsInAdminHierarchy {
    my $vob = shift;

    my @allVobs = ( $vob );
    my $clients = $vob->getVobsAdminClients();
    if( $clients ) {
	foreach my $cl ( @$clients ) {
	    push @allVobs, &allVobsInAdminHierarchy( $cl );
	}
    }
    return @allVobs;
}

#Log::setVerbosity( "debug" );
Transaction::start( -comment => 'TaBasCo installation' );

# declare all hyperlink types
foreach my $hltypeName ( @TaBasCo::Common::Config::allHlTypes ) {
    my $newType = ClearCase::HlType->new( -name => $hltypeName, -vob => $TaBasCo::Common::Config::myVob );
    $newType->create() unless( $newType->exists() );
}

# declare all label types
foreach my $lbtypeName ( @TaBasCo::Common::Config::allLbTypes ) {
    my $newType = ClearCase::LbType->new( -name => $lbtypeName, -vob => $TaBasCo::Common::Config::myVob );
    $newType->create() unless( $newType->exists() );
}

# initialize the main task - based on the default ClearCase branch type 'main'
# the main task gets attached the root path of the installation Vob and
# of all admin client Vobs if the installation Vob is an admin Vob
my $mainTask = TaBasCo::Task::initializeMainTask( $TaBasCo::Common::Config::initialTaBasCoBaseline );
$mainTask->getFloatingRelease()->ensureAsFullRelease();
my $firstMainRelease = $mainTask->createNewRelease();

# create the task tabasco to manage the installed tool within its own task
my $tabascoTask = TaBasCo::Task->new( -name => $TaBasCo::Common::Config::taskNamePrefix . 'tabasco' );
$tabascoTask->create( -baseline => $firstMainRelease );
my $tabascoRootPathElement = ClearCase::Element->new(
    -pathname => $TaBasCo::Common::Config::myVob->getRootElement()->getNormalizedPath() . $OS::Common::Config::slash . $TaBasCo::Common::Config::toolRoot
    );
my @tmp = (); push @tmp, $tabascoRootPathElement;
$tabascoTask->mkPaths( \@tmp );
$tabascoTask->getFloatingRelease()->ensureAsFullRelease();
$tabascoTask->createNewRelease();

# finaly create all trigger types in all Vobs
foreach my $trgVob ( &allVobsInAdminHierarchy( $TaBasCo::Common::Config::myVob ) ) {
    foreach my $trg ( keys %TaBasCo::Common::Config::allTrigger ) {
	my $trt = ClearCase::TrType->new( -name => $trg, -vob => $trgVob );
	$trt->create(
	    -all     => $TaBasCo::Common::Config::allTrigger{ $trg }->{ 'all' },
	    -element => $TaBasCo::Common::Config::allTrigger{ $trg }->{ 'element' },
	    -execu   => '"' . $TaBasCo::Common::Config::allTrigger{ $trg }->{ 'execu' } . '"',
	    -execw   => '"' . $TaBasCo::Common::Config::allTrigger{ $trg }->{ 'execw' } . '"',
	    -command => $TaBasCo::Common::Config::allTrigger{ $trg }->{ 'ops' }
	    );
    }
}

Transaction::commit(); # TaBasCo installation

# load the user interface
my $ui = TaBasCo::UI->new();

my $notice = $TaBasCo::Common::Config::myVob->getRootElement()->getNormalizedPath() . $OS::Common::Config::slash . $TaBasCo::Common::Config::toolRoot;
my $label = $tabascoTask->getLastRelease()->getName();
$ui->okMessage( "

Installation finished.

TaBasCo is installed in $notice.
It is fully labeled with $label.

A task named tabasco has been created to manage changes of the implementation of TaBasCo.

" );
