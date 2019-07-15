package ClearCase::Common::Cleartool;

use strict;
use Carp qw( confess );
use Log;
use IO::Handle;
use POSIX;

# use CtCmd of CC distribution
#use IPC::ClearTool;
use ClearCase::CtCmd;

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $DieOnErrors );
   $VERSION = '0.01';

   require Exporter;
   require AutoLoader;
   require ClearCase::Common::Config;

   @ISA = qw(Exporter);

   @EXPORT = qw(
      $CMD_RC
      @CMD_OUTPUT
      @CMD
   );
   @EXPORT_OK = qw(
      Cleartool
   );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );
   Exporter::export_tags();
} # sub BEGIN()

$DieOnErrors   = (1==1);

# ============================================================================
# Description

=head1 NAME

Cleartool - encapsulates calls of cleartool command

=head1 SYNOPSIS

B<Cleartool.pm> [options]

=head1 DESCRIPTION

<long description>

=head1 USAGE

=head1 METHODS

=cut

sub AUTOLOAD {
   use vars qw( $AUTOLOAD );

   ( my $method = $AUTOLOAD ) =~ s/.*:://;

   no strict 'refs';
   no strict 'subs';
   my $func = <<EOF
       sub ClearCase::Common::Cleartool::$method {
	   my \$rc = cleartool( '$method', \@_ );
	   if ( \$rc == 0 ) {
	       return \$rc;
	   } else {
	       Die( [ 'ct $method failed!', getErrors() ])
		   if \$DieOnErrors;

	       return \$rc;
	   }
   }
EOF
;
      eval( $func );
      Die( [$func, $@ ] ) if $@;

      goto &$AUTOLOAD;

} # AUTOLOAD



my $CMD_RC;
my @CMD_OUTPUT;
my @CMD;



sub ChDir {
   cd ( @_ );
}

sub GetCwd {
   pwd();

   return getOutputLine();
}

sub execute {
   @CMD  = @_;
   @CMD_OUTPUT = ();

   Exec( join( ' ', @CMD ) . "\n" );

   ### pipe( PARENT_R, CHILD_W );
   pipe( PARENT_R, CHILD_W );

   my $rc;
   if( my $pid = fork() )
   {
      # ======================================================================
      # PARENT
      #
      close CHILD_W;

      # ======================================================================
      # We are the parent
      my $line;
      for(;;) {
         $line = readline (*PARENT_R );
         last if not $line;
         push @CMD_OUTPUT, $line;
      }
      close PARENT_R;

      waitpid( $pid, 0 );
      $rc = $?;
   }
   else
   {
      # ======================================================================
      # CHILD
      #
      close PARENT_R;

      # set STDOUT to CHILD_W and AUTOFLUSH
      open STDOUT, ">&=" . fileno( CHILD_W );
      $| = 1;

      if( not exec ( "@CMD" ) ) {
         # the program couldn't be executed
         my $msg = "ERROR: can't exec ( ";
         $msg.=join( ' ', @CMD );
         $msg.=") - ".$!;

         close CHILD_W;

         Die( $msg );
      }
      # NOT REACHED
   }

   $CMD_RC = $rc;

   # return the output
   return $CMD_RC == 0;

} # execute


use vars qw( @CT_ERRORS @CT_WARNINGS @CT_OUTPUT $CT_RC $CT );


sub setEcho {
   my ( $echo ) = @_;

   my $oldValue = $CT->{'DBGLEVEL'};

   $echo
   ?  $CT->dbglevel(2)
   :  $CT->dbglevel(0);

   return $oldValue;
}

sub disableErrorOut {
    my $p = $CT->{ 'CT_ERROUT' };
    $CT->{ 'CT_ERROUT' } = 0;
    return $p;
}

sub enableErrorOut {
    my $p = $CT->{ 'CT_ERROUT' };
    $CT->{ 'CT_ERROUT' } = 1;
    return $p;
}

sub disableDieOnErrors {
    my $p = $DieOnErrors;
    $DieOnErrors = 0;
    return $p;
}

sub enableDieOnErrors {
    my $p = $DieOnErrors;
    $DieOnErrors = 1;
    return $p;
}

sub registerRemoteHost
  {
    my $arrayRef = shift;
    my $hostname = shift;

    push @$arrayRef, 'REMOTEHOST:' . $hostname;
  }

sub cleartool {

    # initialize ClearTool object
    if ( not defined $CT ) {
	$CT = ClearCase::CtCmd->new();
	$CT->{ 'CT_ERROUT' } = 1;
    }

    @CT_ERRORS = ();
    @CT_WARNINGS = ();
    @CT_OUTPUT = ();
    $CT_RC = undef;

    # store error and warnings internal in cleartool subprocess
    #$CT->store;

    Exec( [ 'ct ' . join( ' ', @_ )] );
    my @erg = ();
    @erg = $CT->exec( join( ' ', @_ ) );
    $CT_RC = $erg[0];

    my @erg_out = split /\n/, $erg[1];
    my @erg_err = split /\n/, $erg[2];
    grep s/$/\n/, @erg_out;
    grep s/$/\n/, @erg_err;

    foreach( @erg_out ) {
	s/cleartool: *//;
	if( /Error: *(.*)/ ) {
	    push @CT_ERRORS, $1;
	} elsif( /Warning: *(.*)/ ) {
	    push @CT_WARNINGS, $1;
	} else {
	    push @CT_OUTPUT, $_;
	}
    }

    foreach( @erg_err ) {
	s/cleartool: *//;
	if( /Error: *(.*)/ ) {
	    push @CT_ERRORS, $1;
	} elsif( /Warning: *(.*)/ ) {
	    push @CT_WARNINGS, $1;
	}
    }
    
    @CT_WARNINGS = grep (!m/which is different from set view/, @CT_WARNINGS);

    Debug( [ "Cleartool RC ". $CT_RC ] );
    Debug( [ "Cleartool Output", @CT_OUTPUT ] )
	if @CT_OUTPUT;
    Warn( [ "Cleartool Warning", @CT_WARNINGS ] )
	if ( @CT_WARNINGS and $CT->{ 'CT_ERROUT' } );
    Error( [ "Cleartool Errors", @CT_ERRORS ] )
	if ( @CT_ERRORS and $CT->{ 'CT_ERROUT' } );

    return $CT_RC;
} # cleartool

sub getRC {
   return $CT_RC;
}

sub getErrors {
   return @CT_ERRORS if wantarray();
   return $#CT_ERRORS;
}

sub getWarnings {
   return @CT_WARNINGS if wantarray();
   return $#CT_WARNINGS;
}

sub getOutput {
   return @CT_OUTPUT if wantarray();
   return $#CT_OUTPUT;
}

sub getRawOutput {
   return @CMD_OUTPUT if wantarray();
   return $#CMD_OUTPUT;
}

sub getOutputLine {
   Die("Got more than one line from cleartool")
      if $#CT_OUTPUT > 0;
   return undef
      if $#CT_OUTPUT < 0;

   return $CT_OUTPUT[0];
}

1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2007, 2014 Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com

=head1 SEE ALSO

=cut
