
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
}

use Log;

Log::setVerbosity( "debug" );
Transaction::start( -comment => 'TaBasCo installation' );

my $configFile = $base . $OS::Common::Config::slash . $TaBasCo::Common::Config::configFile;
my $vobTag = File::Basename::dirname( $base );

my $vob = ClearCase::InitVob( -tag => $vobTag );

# create the hyperlink type to link paths to the branches, what we need first
my $pathLinkType = ClearCase::InitHlType( -name => $TaBasCo::Common::Config::pathLink, -vob => $vob );
$pathLinkType->create();

# create the configuration file
ClearCase::checkout(
		    -pathname => $base
		   );
ClearCase::mkelem(
		  -eltype   => 'text_file',
		  -pathname => $configFile
		 );

# now create the hyperlink from the first Task (= branch main of the configuration file)
# to the Vob root path element
my $mainTask = TaBasCo::Task->new( -pathname => $configFile . '@@' . $OS::Common::Config::slash . 'main' );
my $vobRootElement = ClearCase::InitElement( -pathname => $vobTag . $OS::Common::Config::slash . '.@@' );

my $initialPathLink = ClearCase::InitHyperLink(
    -hltype => $pathlinkType,
    -from => $mainTask,
    -to => $vobRootElement
    );
$initialPathLink->create();

# create the label type MAIN_NEXT
ClearCase::InitLbType( -name => uc( 'main' . $TaBasCo::Common::Config::nextLabelExtension ), -vob => $vob
                            )->create();

# create the label type CSPEC
ClearCase::InitLbType( -name => $TaBasCo::Common::Config::cspecLabel, -vob => $vob
                            )->create( -pbranch => 1 );


# now create the initial config spec for the initial task
$mainTask->createConfigSpec();

# the initial config spec has been written.
# and the CSPEC label has been attached.
# now we have to checkin and check out again
# to create the initial release
Transaction::commit();
Transaction::start( -comment => "create initial release" );
ClearCase::checkout(
                    -pathname => $configFile
                   );

# get the new release name
my $relName = $mainTask->nextReleaseName();

# create the release
$mainTask->createNewRelease( $relName, ClearCase::InitView( $ENV{ 'CLEARCASE_VIEW' } ) );

# create the tools label type
ClearCase::InitLbType( -name => $TaBasCo::Common::Config::toolSelectLabel, -vob => $vob )->create();

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
    my $trt = ClearCase::InitTrType( -name => $trg, -vob => $vob );
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
my $ui = TaBasCo::InitUI();

$ui->okMessage( "Installation finished.
The starting baseline is $relName.
You should now label your configuration
from where you want to start from with
$relName.
At least the root directory of the Vob
has to be labeled.
And DO NOT label the imported $TaBasCo::Common::Config::toolRoot subtree !!! " );
