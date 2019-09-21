
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
    }
  unshift @INC, @INCL_LIB;
}

use OS;
use ClearCase;
use TaBasCo;
use Log;

sub allVobsInAdminHierarchy {
    my $vob = shift;

    my @allVobs = ( $vob );
    my $clients = $vob->getClientVobs();
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

# declare all attribute types
# we expect only integer attribute types with a default value
foreach my $attributeName ( @TaBasCo::Common::Config::allAtTypes ) {
    my $newType = ClearCase::AtType->new( -name => $attributeName, -vob => $TaBasCo::Common::Config::myVob );
    $newType->create( -valuetype => 'integer', -defaultvalue => 1 ) unless( $newType->exists() );
}

# create the task tabasco to manage the installed tool within its own task
my $tabascoTask = TaBasCo::Task->new( -name => $TaBasCo::Common::Config::maintenanceTask );
my $tabascoRootPathElement = ClearCase::Element->new(
    -pathname => $TaBasCo::Common::Config::$installRoot
    );
my @tmp = (); push @tmp, $tabascoRootPathElement;

# the Vob root path will be labeled as well by TaBasCo::create
$tabascoTask->create(
    -elements => \@tmp,
    -comment => 'TABASCO Maintenance Task'
    );


# finaly create all trigger types in all Vobs
# we expect that all Vobs are owned by the calling user
foreach my $trgVob ( &allVobsInAdminHierarchy( $TaBasCo::Common::Config::myVob->getAdminVobHierarchyRoot() ) ) {
    foreach my $trg ( keys %TaBasCo::Common::Config::allTrigger ) {
	my $trt = ClearCase::TrType->new( -name => $trg, -vob => $trgVob );
	$trt->create(
	    -all     => $TaBasCo::Common::Config::allTrigger{ $trg }->{ 'all' },
	    -element => $TaBasCo::Common::Config::allTrigger{ $trg }->{ 'element' },
	    -execu   => '"' . $TaBasCo::Common::Config::allTrigger{ $trg }->{ 'execu' } . '"',
	    -execw   => '"' . $TaBasCo::Common::Config::allTrigger{ $trg }->{ 'execw' } . '"',
	    -command => $TaBasCo::Common::Config::allTrigger{ $trg }->{ 'ops' },
	    -name    => $trt->getFullName()
	    );
    }
}

Transaction::commit(); # TaBasCo installation

# load the user interface
my $ui = TaBasCo::UI->new();

my $notice = $TaBasCo::Common::Config::$installRoot;
my $label = $tabascoTask->getBaseline()->getName();
my $tabasName = $tabascoTask->getName();
$ui->okMessage( "

Installation finished.

TaBasCo is installed in $notice.

A task named $tabasName has been created to manage changes of the TaBasCo implementation.
The TaBasCo installation has been fully labeled with $label.

" );
