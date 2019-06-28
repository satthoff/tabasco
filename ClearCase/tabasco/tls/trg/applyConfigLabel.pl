# post checkin trigger to attach configuration label
# 
use strict;

my $label = uc( $ENV{ CLEARCASE_BRTYPE } ) . '_NEXT';
my $rc = system( "cleartool mklabel -repl $label $ENV{ CLEARCASE_PN } 2>/dev/null 1>/dev/null" );
exit $rc;
