package TaBasCo;

use strict;
use Carp;

sub BEGIN {
   require Transaction;
   require ClearCase::Common::Config;
   require ClearCase::Common::Cleartool;
}

use Log;

sub AUTOLOAD {
    use vars qw( $AUTOLOAD );

    ( my $method = $AUTOLOAD ) =~ s/.*:://;

    if( $method =~ m/^Init(\S+)$/ ) { # request to create object of package method = InitPackage
	my $package = 'TaBasCo::' . $1;
	eval "require $package";
	Die( [ "require of package $package failed." ] ) if $@;

	no strict 'refs';
	no strict 'subs';
	my $func = <<EOF
	    sub TaBasCo::$method {
		return $package->new( \@_ );
	}
EOF
;
	eval( "$func" );
	Die( [$func, $@ ] ) if $@;
	goto &$AUTOLOAD;
    }
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

