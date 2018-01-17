package IF_template;

use strict;
use Carp;
use Log;
use Transaction;


sub BEGIN {
   # =========================================================================
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
   $VERSION = '0.01';
   require Exporter;
   @ISA = qw(Exporter);
   @EXPORT = qw(
   );
   @EXPORT_OK = qw(
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );

   
} # sub BEGIN()


# ============================================================================
# Description

=head1 NAME

IF_template - <short description>

=head1 SYNOPSIS

B<IF_template.pm> [options]

=head1 DESCRIPTION

<long description>

=head1 USAGE

=head1 METHODS

=cut


sub AUTOLOAD {
    use vars qw( $AUTOLOAD );

    ( my $method = $AUTOLOAD ) =~ s/.*:://;

    if( $method =~ m/^[a-z]/ ) {
	my $package = "IF_template::Command::$method";
	eval "require $package";
	Die( [ "require of package IF_template::Command::$method failed." ] ) if $@;

	no strict 'refs';
	no strict 'subs';
	my $func = <<EOF
	    sub IF_template::$method { # method is a command of the IF_template interface
		my \$action = $package->new( -transaction => Transaction::getTransaction(), \@_  );
		\$action->execute();
	}
EOF
;
	eval( "$func" );
	Die( [$func, $@ ] ) if $@;

    } elsif( $method =~ m/^[A-Z]/ ) { # method is a perl package (IF_template/<method>.pm) of the IF_template interface
	my $package = "IF_template::$method";
	eval "require $package";
	Die( [ "require of package IF_template::$method failed." ] )  if $@;

	no strict 'refs';
	no strict 'subs';
	my $func = <<EOF
	    sub IF_template::$method { return IF_template::$method->new( \@_ ); }
EOF
;
	eval( "$func" );
	Die( [$func, $@ ] ) if $@;

    } else { # Error: method must start with upper or lower case letter 
	Die( [ "methods for AUTOLOAD in package IF_template must start with upper or lower case letter" ] );
    }

    goto &$AUTOLOAD;

} # AUTOLOAD

1;

__END__

=head1 EXAMPLES

=head1 AUTHOR INFORMATION

 Copyright (C) 2006 Uwe Satthoff

=head1 BUGS

 Address bug reports and comments to:
   uwe@satthoff.eu

=head1 SEE ALSO

=cut
