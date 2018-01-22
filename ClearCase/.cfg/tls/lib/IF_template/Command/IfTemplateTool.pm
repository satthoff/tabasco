package IF_template::IfTemplateTool;

use strict;
use Carp qw( confess );
use Log;
use IO::Handle;
use POSIX;

# according to ASML environment we replace IPC::ChildSafe by ClearCase::CtCmd
#use IPC::ClearTool;
use lib '/sdev/user/lib/site_perl';
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

   Debug( [ 'enter AUTOLOAD in ClearCase::Common::Cleartool with AUTOLOAD = ' . $AUTOLOAD ] );

   
   ( my $method = $AUTOLOAD ) =~ s/.*:://;

   my $package = "ClearCase::Command::$method";
   eval "require $package";
   confess $@ if $@;

   no strict 'refs';
   no strict 'subs';
   my $func = <<EOF
       sub ClearCase::Common::Cleartool::$method {
	   Debug( [ "Enter method ClearCase::Common::Cleartool::$method" ] );
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
   $CT->{ 'CT_ERROUT' } = 0;
}

sub enableErrorOut {
   $CT->{ 'CT_ERROUT' } = 1;
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


   if( $_[1] =~ m/^REMOTEHOST:(\S+)/ )
     {
       my @cmd = ();
       push @cmd, "ssh $1";
       my $ct = join('/', $ENV{ATRIAHOME} || '/usr/atria', 'bin/cleartool');
       $ct = 'cleartool' unless -x $ct;
       push @cmd, $ct;
       push @cmd, shift @_;
       shift @_;
       push @cmd, @_;
       my $tmpout = POSIX::tmpnam();
       my $tmperr = POSIX::tmpnam();

       Exec( [ join( ' ', @cmd )] );
       $CT_RC = system( "@cmd 2>$tmperr 1>$tmpout" );

       open FD, "$tmpout" or Die( [ 'can not read temp file ' . $tmpout ] );
       my @tmp = <FD>;
       close FD;
       unlink $tmpout;
       foreach( @tmp )
	 {
	   if( /Warning/i )
	     {
	       push @CT_WARNINGS, $_;
	     }
	   else
	     {
	       push @CT_OUTPUT, $_;
	     }
	 }

       open FD, "$tmperr" or Die( [ 'can not read temp file ' . $tmperr ] );
       @tmp = <FD>;
       close FD;
       unlink $tmperr;
       foreach( @tmp )
	 {
	   if( /Warning/i )
	     {
	       push @CT_WARNINGS, $_;
	     }
	   else
	     {
	       push @CT_ERRORS, $_;
	     }
	 }

       $CT_RC =  ( $#CT_ERRORS > -1 );
     }
   else
     {
       Exec( [ 'ct ' . join( ' ', @_ )] );
       my @erg = ();
       @erg = $CT->exec( join( ' ', @_ ) );
       $CT_RC = $erg[0];

       my @erg_out = split /\n/, $erg[1];
       my @erg_err = split /\n/, $erg[2];
       grep s/$/\n/, @erg_out;
       grep s/$/\n/, @erg_err;

       foreach( @erg_out )
	 {
	   s/cleartool: *//;

	   if( /Error: *(.*)/ ) {
	     push @CT_ERRORS, $1;

	   } elsif( /Warning: *(.*)/ ) {
	     push @CT_WARNINGS, $1;

	   } else {
	     push @CT_OUTPUT, $_;
	   }
	 }

       foreach( @erg_err )
	 {
	   s/cleartool: *//;

	   if( /Error: *(.*)/ ) {
	     push @CT_ERRORS, $1;

	   } elsif( /Warning: *(.*)/ ) {
	     push @CT_WARNINGS, $1;

	   }
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

Address bug reports and comments to: uwe@satthoff.eu

=head1 SEE ALSO

=cut
