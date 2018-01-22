package TaBasCo;

use strict;
use Carp;

use Log;
use Transaction;
use Data;
use ClearCase;
use OS;

use TaBasCo::UI;
use TaBasCo::Config;
use TaBasCo::Task;
use TaBasCo::Release;


BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

   require Exporter;
   require AutoLoader;

   @ISA = qw(Exporter AutoLoader);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
   # TAG1 => [...],
   );
   $VERSION = '0.01';

};

1;

__END__

=head1 EXAMPLES

=head1 AUTHOR INFORMATION

 Copyright (C) 2010   Uwe Satthoff 

=head1 BUGS

 Address bug reports and comments to:
	uwe@satthoff.eu

=head1 SEE ALSO

=cut

