package ClearCase::Element;

use strict;
use Carp;
use File::Basename;
use Log;

BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %DATA);
   $VERSION = '0.01';
   require Exporter;
   require Data;
   require ClearCase::Common::CCPath;

   @ISA = qw(Exporter Data ClearCase::Common::CCPath );

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   %DATA = (
      );

   Data::init(
      PACKAGE  => __PACKAGE__,
      SUPER    => 'ClearCase::Common::CCPath'
      );

} # BEGIN()

1;

__END__

=head1 EXAMPLES

=head1 AUTHOR INFORMATION

 Copyright (C) 2007 Uwe Satthoff

=head1 BUGS

 Address bug reports and comments to:
   satthoff@icloud.com

=head1 SEE ALSO

=cut

##############################################################################

