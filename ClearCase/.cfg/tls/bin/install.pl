
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

$base = File::Basename::dirname( $base );
my $configFile = $base . $OS::Common::Config::slash . $TaBasCo::Common::Config::configFile;
my $vobTag = File::Basename::dirname( $base );

my $vob = $ClearCase::Common::Config::myHost->getRegion()->getVob( $vobTag );

# create the label type MAIN_NEXT in my Vob
$vob->ensureLabelType( -name => uc( 'main' . $TaBasCo::Common::Config::nextLabelExtension ) );

# create the label type CSPEC in my Vob
$vob->ensureLabelType( -name => $TaBasCo::Common::Config::cspecLabel, -pbranch => 1 );

# create the hyperlink type in my Vob to link paths to the branches (tasks)
my $pathLinkType = $vob->ensureHyperlinkType( -name => $TaBasCo::Common::Config::pathLink );

# create the tools label type
$vob->ensureLabelType( -name => $TaBasCo::Common::Config::toolSelectLabel );

# create the configuration file
ClearCase::checkout(
		    -argv => $base
		   );
ClearCase::mkelem(
		  -eltype   => 'text_file',
		  -argv => $configFile
		 );

# now create the hyperlink from the first Task (= branch main of the configuration file)
# to the Vob root path element
my $mainTask = TaBasCo::Task->getMainTask();
my $initialPathLink = ClearCase::HyperLink->new(
    -hltype => $pathLinkType,
    -from => $mainTask,
    -to => $vob->getRootElement()
    );
$initialPathLink->create();


# now create the initial config spec for the initial task
$mainTask->createConfigSpec();

# the initial config spec has been written.
# and the CSPEC label has been attached.
# now we have to checkin and check out again
# to create the initial release
Transaction::commit();
Transaction::start( -comment => "create initial release" );
ClearCase::checkout(
                    -argv => $configFile
                   );

# get the new release name
my $relName = $mainTask->nextReleaseName();

# create the release
$mainTask->createNewRelease( $relName, ClearCase::View->new( $ENV{ 'CLEARCASE_VIEW' } ) );

# label the installation
ClearCase::mklabel(
		   -pathname => $base . $OS::Common::Config::slash . $TaBasCo::Common::Config::toolPath,
		   -label    => $TaBasCo::Common::Config::toolSelectLabel,
		   -recurse  => 1
		  );
ClearCase::mklabel(
                   -pathname => $base,
                   -label    => $TaBasCo::Common::Config::toolSelectLabel
                  );

Transaction::commit();

# finaly create all trigger types
foreach my $trg ( keys %TaBasCo::Common::Config::allTrigger )
  {
    my $trt = ClearCase::TrType->new( -name => $trg, -vob => $vob );
    $trt->create(
                 -all     => $TaBasCo::Common::Config::allTrigger{ $trg }->{ 'all' },
                 -element => $TaBasCo::Common::Config::allTrigger{ $trg }->{ 'element' },
                 -execu   => '"' . $TaBasCo::Common::Config::allTrigger{ $trg }->{ 'execu' } . '"',
                 -execw   => '"' . $TaBasCo::Common::Config::allTrigger{ $trg }->{ 'execw' } . '"',
                 -command => $TaBasCo::Common::Config::allTrigger{ $trg }->{ 'ops' }
                );
    if( defined( $TaBasCo::Common::Config::allTrigger{ $trg }->{ 'att' } ) )
      {
        $trt->attach( $configFile . '@@' );
      }
  }

# load the user interface
my $ui = TaBasCo::UI->new();

$ui->okMessage( "Installation finished.
The starting baseline is $relName.
You should now label your configuration
from where you want to start from with
$relName.
At least the root directory of the Vob
has to be labeled.
And DO NOT label the imported $TaBasCo::Common::Config::toolRoot subtree !!! " );
