package TaBasCo;

use strict;
use Carp;

sub BEGIN {
   require Transaction;
   require Log;
   require ClearCase::Common::Config;
   require ClearCase::Common::Cleartool;
   require TaBasCo::Task;
   require TaBasCo::Release;
}


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

