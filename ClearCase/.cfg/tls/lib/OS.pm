package OS;

use strict;
use Carp;
use Log;
use Transaction;
use OS::Config;


BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

   require Exporter;

   @ISA = qw(Exporter);

   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
   # TAG1 => [...],
   );
   $VERSION = '0.01';

};

sub AUTOLOAD {
    use vars qw( $AUTOLOAD );

    ( my $method = $AUTOLOAD ) =~ s/.*:://;

    if( $method =~ m/^[a-z]/ ) {
	my $package = "OS::Command::$method";
	eval "require $package";
	Die( [ "require of package OS::Command::$method failed." ] ) if $@;

	no strict 'refs';
	no strict 'subs';
	my $func = <<EOF
	    sub OS::$method { # method is a command of the OS interface
		my \$action = $package->new( -transaction => Transaction::getTransaction(), \@_  );
		\$action->execute();
	}
EOF
;
	eval( "$func" );
	Die( [$func, $@ ] ) if $@;

    } elsif( $method =~ m/^[A-Z]/ ) { # method is a perl package (OS/<method>.pm) of the OS interface
	my $package = "OS::$method";
	eval "require $package";
	Die( [ "require of package OS::$method failed." ] )  if $@;

	no strict 'refs';
	no strict 'subs';
	my $func = <<EOF
	    sub OS::$method { return OS::$method->new( \@_ ); }
EOF
;
	eval( "$func" );
	Die( [$func, $@ ] ) if $@;

    } else { # Error: method must start with upper or lower case letter 
	Die( [ "methods for AUTOLOAD in package OS must start with upper or lower case letter" ] );
    }

    goto &$AUTOLOAD;

} # AUTOLOAD

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

