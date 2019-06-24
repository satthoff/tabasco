package TaBasCo;

use strict;
use Carp;

sub BEGIN {
   require Transaction;
   require Log;
   require ClearCase::Common::Config;
   require ClearCase::Common::Cleartool;
   require TaBasCo::Common::Config;
   require TaBasCo::Task;
   require TaBasCo::Release;
   require TaBasCo::Environment;
   require TaBasCo::UI;
}


1;

__END__

=head1 EXAMPLES

=head1 AUTHOR INFORMATION

 Copyright (C) 2010   Uwe Satthoff 

=head1 BUGS

 Address bug reports and comments to:
	satthoff@icloud.com

=head1 SEE ALSO

=cut

