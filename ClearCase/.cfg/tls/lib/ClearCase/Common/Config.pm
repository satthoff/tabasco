package ClearCase::Common::Config;

use ClearCase::Host;

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

use vars qw/ $myHost $adminVobLink /;

BEGIN {
    $adminVobLink = 'AdminVOB';
    my $hostname = `hostname`;
    chomp $hostname;
    $myHost = ClearCase::Host->new( -hostname => $hostname );
    
}

# ============================================================================
# ClearCase standard element types

%StandardElementTypes =
  (
   'binary_delta_file'    => 'Predefined element type used to represent a file in binary delta format.',
   'compressed_file'      => 'Predefined element type used to represent a file in compressed format.',
   'compressed_text_file' => 'Predefined element type used to represent a text file in compressed format.',
   'directory'            => 'Predefined element type used to represent a directory.',
   'file'                 => 'Predefined element type used to represent a file.',
   'file_system_object'   => 'Predefined element type used to represent a file system object.',
   'html'                 => 'Predefined element type used to represent an HTML file.',
   'ms_word'              => 'Predefined element type used to represent a Microsoft Word document.',
   'rose'                 => 'Predefined element type used to represent a Rational Rose model.',
   'text_file'            => 'Predefined element type used to represent a text file.',
   'xml'                  => 'Predefined element type used to represent an XML file.'
  );


# ============================================================================
# Hash with regular expression for parsing the output of 'ct lsview'.
%CC_LSVIEW_VALUES = (
  #TAG        =>    'Tag: (.*)',
   Tag        =>    'Tag: (.*)',
   Path       =>    '  Global path: (.*)',
   Tag_UUID   =>    '  View tag uuid: (.*)\n',
   Server     =>    '  Server host: (.*)\n',
   Active     =>    '  Active: (.*)\n',
   Host       =>    'View on host: (.*)\n',
   UUID       =>    'View uuid: (.*)\n',
   Owner      =>    'View owner: (.*)\n',
   Type       =>    'View attributes: (.*)\n'
   );

# ============================================================================
# Hash with regular expression for parsing the output of 'ct lsview'.
%CC_DESCRIBE_VALUES = (
  #TAG        =>    'Tag: (.*)',
  ELEMENT_TYPE       =>    '  element type: (.*)',
  PATH               =>    '(?:directory |)version "(.*)"$',
  PREDECESSOR        =>    '  predecessor version: (.*)$'
   );

%CC_DESCRIBE_VOB_VALUES = (
  #TAG        =>    'Tag: (.*)',
  BASE                     =>  'versioned object base "(.*)"$',
  CREATED                  =>  '  created (.*)$',
  FAMILY_FEATURE           =>  '  VOB family feature level: (.*)$',
  DATABASE_SCHEMA_VERSION  =>  '  database schema version: (.*)$',
  OWNER                    =>  '    owner .*/(.*)$'
   );

# we hope that no white spaces are used in filenames and CC type names
#$CC_FILENAME_PATTERN = '[A-Za-z-_0-9/\.+]+';
#$CC_VERSION_PATTERN  = '[A-Za-z-_0-9\/\.]+';
#$CC_EXTENDED_PATTERN = '[A-Za-z-_0-9\/\.@]+';
#$CC_LBTYPE_PATTERN   = '[A-Za-z_0-9\.]+';
#$CC_HLTYPE_PATTERN   = '[A-Za-z_0-9\.]+';
$CC_FILENAME_PATTERN = '.+';
$CC_VERSION_PATTERN  = '.+';
$CC_EXTENDED_PATTERN = '.+';
$CC_LBTYPE_PATTERN   = '.+';
$CC_HLTYPE_PATTERN   = '.+';
$CC_HL_PATTERN       = '\S+';

$CC_CHECKOUT_OUTPUT = "Checked out \"($CC_FILENAME_PATTERN)\" from version \"($CC_VERSION_PATTERN)\".";
$CC_CHECKIN_OUTPUT  = "Checked in \"($CC_FILENAME_PATTERN)\" version \"($CC_VERSION_PATTERN)\".";
%CC_UNCHECKOUT_OUTPUT  = (
   UNCO     => "Checkout cancelled for \"($CC_FILENAME_PATTERN)\".",
   KEEP     => "Private version of \"($CC_FILENAME_PATTERN)\" saved in \"($CC_FILENAME_PATTERN)\"."
   );

%CC_LS_OUTPUT = (
   NORMAL  => "($CC_EXTENDED_PATTERN) from ($CC_VERSION_PATTERN) .*"
   );

%CC_LBTYPE_OUTPUT = (
   CREATE  => "Created label \"($CC_LBTYPE_PATTERN)\" on \"($CC_FILENAME_PATTERN)\" version \"($CC_VERSION_PATTERN)\".",
   REMOVE  => "Removed label \"($CC_LBTYPE_PATTERN)\" from \"($CC_FILENAME_PATTERN)\" version \"($CC_VERSION_PATTERN)\".",
   MOVE    => "Moved label	\"($CC_LBTYPE_PATTERN)\" on \"($CC_FILENAME_PATTERN)\" from version \"($CC_VERSION_PATTERN)\" to \"$CC_VERSION_PATTERN\"."
   );

%CC_MKHLINK_OUTPUT = (
   CREATE => "Created hyperlink \"($CC_HL_PATTERN)\""
   );

$CC_RM_DISPLAY = 'Uncataloged';
%CC_RMNAME_OUTPUT = (
   RMNAME => "$CC_RM_DISPLAY .*\"($CC_FILENAME_PATTERN)\".",
   LF     => "Moving object to vob lost+found directory as \"($CC_FILENAME_PATTERN)\"."
   );

%CC_ELEMENT_TYPES = (
   'file element'       =>    'ClearCase::File',
   'directory element'  =>    'ClearCase::Directory' );

1;
