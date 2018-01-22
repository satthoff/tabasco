
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

my $configFile = $base . $OS::Config::slash . $TaBasCo::Config::configFile;
my $vobTag = File::Basename::dirname( $base );

my $vob = ClearCase::InitVob( -tag => $vobTag );

# create the hyperlink type to link paths to the branches, what we need first
my $pathLink = ClearCase::InitHlType( -name => $TaBasCo::Config::pathLink, -vob => $vob )->create();

# create the configuration file
ClearCase::checkout(
		    -pathname => $base
		   );
ClearCase::mkelem(
		  -eltype   => 'text_file',
		  -pathname => $configFile
		 );

# now create the hyperlink from the branch main of the configuration file
# to the Vob root path element
ClearCase::mkhlink(
                   -hltype => $pathLink->getName(),
                   -from   => $configFile . '@@' . $OS::Config::slash . 'main',
                   -to     => $vobTag . $OS::Config::slash . '.@@'
                  );

# load the initial task
my $task = TaBasCo::Task->new( -pathname => $configFile . '/main' );

# create the label type MAIN_NEXT
ClearCase::InitLbType( -name => uc( 'main' . $TaBasCo::Config::nextLabelExtension ), -vob => $vob
                            )->create();

# create the label type CSPEC
ClearCase::InitLbType( -name => $TaBasCo::Config::cspecLabel, -vob => $vob
                            )->create( -pbranch => 1 );


# now create the initial config spec for the initial task
$task->createConfigSpec();

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
my $relName = $task->nextReleaseName();

# create the release
$task->createNewRelease( $relName );

# create the tools label type
ClearCase::InitLbType( -name => $TaBasCo::Config::toolSelectLabel, -vob => $vob )->create();

# label the installation
ClearCase::mklabel(
		   -pathname => $base . $OS::Config::slash . $TaBasCo::Config::toolPath,
		   -label    => $TaBasCo::Config::toolSelectLabel,
		   -recurse  => 1
		  );
ClearCase::mklabel(
                   -pathname => $base,
                   -label    => $TaBasCo::Config::toolSelectLabel
                  );

Transaction::commit();

# finaly create all trigger types
foreach my $trg ( keys %TaBasCo::Config::allTrigger )
  {
    my $trt = ClearCase::InitTrType( -name => $trg, -vob => $vob );
    $trt->create(
                 -all     => $TaBasCo::Config::allTrigger{ $trg }->{ 'all' },
                 -element => $TaBasCo::Config::allTrigger{ $trg }->{ 'element' },
                 -execu   => '"' . $TaBasCo::Config::allTrigger{ $trg }->{ 'execu' } . '"',
                 -execw   => '"' . $TaBasCo::Config::allTrigger{ $trg }->{ 'execw' } . '"',
                 -command => $TaBasCo::Config::allTrigger{ $trg }->{ 'ops' }
                );
    if( defined( $TaBasCo::Config::allTrigger{ $trg }->{ 'att' } ) )
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
And DO NOT label the imported $TaBasCo::Config::toolRoot subtree !!! " );
