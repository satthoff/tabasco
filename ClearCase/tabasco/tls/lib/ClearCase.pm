package ClearCase;

use strict;
use Carp;

sub BEGIN {
   require Transaction;
   require ClearCase::Common::Config;
   require ClearCase::Common::Cleartool;
   require ClearCase::Version;
   require ClearCase::Branch;
   require ClearCase::Registry;
   require ClearCase::Region;
   require ClearCase::BrType;
   require ClearCase::Element;
   require ClearCase::View;
   require ClearCase::Vob;
   require ClearCase::LbType;
   require ClearCase::HlType;
   require ClearCase::TrType;
   require ClearCase::AtType;
   require ClearCase::HyperLink;
   require ClearCase::Replica;
   require ClearCase::Attribute;
}

use Log;

my $CC_VERSION    = undef;

# ============================================================================
# Description

=head1 NAME

ClearCase - <short description>

=head1 SYNOPSIS

B<ClearCase.pm> [options]

=head1 DESCRIPTION

<long description>

=head1 USAGE

=head1 METHODS

=cut

sub AUTOLOAD {
    use vars qw( $AUTOLOAD );

    ( my $method = $AUTOLOAD ) =~ s/.*:://;

    Debug( [ 'enter AUTOLOAD in package ClearCase with AUTOLOAD = ' . $AUTOLOAD ] );

    my $package = "ClearCase::Command::$method";
    eval "require $package";
    Die( [ "require of package $package failed.", "$@" ] ) if $@;

    no strict 'refs';
    no strict 'subs';
    my $func = <<EOF
	sub ClearCase::$method { # method is a command of the ClearCase interface
	    my \$action = $package->new( -transaction => Transaction::getTransaction(), \@_  );
	    \$action->execute();
    }
EOF
;
    eval( "$func" );
    Die( [$func, $@ ] ) if $@;
    goto &$AUTOLOAD;

} # AUTOLOAD

sub getErrors {
    return ClearCase::Common::Cleartool::getErrors();
}

sub getWarnings {
    return ClearCase::Common::Cleartool::getWarnings();
}

sub getOutput {
    return ClearCase::Common::Cleartool::getOutput();
}

sub getOutputLine {
    return ClearCase::Common::Cleartool::getOutputLine();
}

sub getRC {
    return ClearCase::Common::Cleartool::getRC();
}

sub disableErrorOut {
    ClearCase::Common::Cleartool::disableErrorOut();
    return;
}

sub enableErrorOut {
    ClearCase::Common::Cleartool::enableErrorOut();
    return;
}

sub disableDieOnErrors {
    ClearCase::Common::Cleartool::disableDieOnErrors();
    return;
}

sub enableDieOnErrors {
    ClearCase::Common::Cleartool::enableDieOnErrors();
    return;
}

1;

__END__

=head1 EXAMPLES

=head1 AUTHOR INFORMATION

 Copyright (C) 2006, 2017 Uwe Satthoff

=head1 BUGS

 Address bug reports and comments to:
   satthoff@icloud.com

=head1 SEE ALSO

=cut
