package CLI;

use strict;

use CLI::Config;
use CLI::Command;


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
	satthoff@icloud.com

=head1 SEE ALSO

=cut

