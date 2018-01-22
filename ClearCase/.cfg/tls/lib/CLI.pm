package CLI;

use strict;
use Carp;
use File::Temp;

use CLI::Config;
use CLI::Command;
use OS;
use Transaction;
use ClearCase;
use TaBasCo;
use Log;


sub new()
{
  my $proto = shift;
  my $class = ref ($proto) || $proto;
  my $self  = {};

  Die("CLI::new() not allowed")
    if not defined $proto;

  bless $self, $class;
  return $self;
} # new ()

1;

__END__

=head1 EXAMPLES

=head1 AUTHOR INFORMATION

 Copyright (C) 2008, 2012   Uwe Satthoff 

=head1 BUGS

 Address bug reports and comments to:
	uwe@satthoff.eu

=head1 SEE ALSO

=cut

