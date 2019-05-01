package OS::Common::OsTool;

use strict;
use Carp qw( confess );
use Log;
use IO::Handle;
use IO::File;
use POSIX;

# use OS::Shell;
# not used, because does not work correctly.
# does not return from child process if used more than once.

sub BEGIN {
   use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $DieOnErrors );
   $VERSION = '0.01';

   require Exporter;

   @ISA = qw(Exporter);

   @EXPORT = qw(
      $CMD_RC
      @CMD_OUTPUT
      @CMD
   );
   @EXPORT_OK = qw(
		   oscmd
		   registerRemoteHost
		   registerBackground
		   disableErrorStop
		   enableErrorStop
		  );
   %EXPORT_TAGS = (
      # TAG1 => [...],
   );
   Exporter::export_tags();
} # sub BEGIN()

$DieOnErrors   = (1==1);



sub AUTOLOAD {
   use vars qw( $AUTOLOAD );

   ( my $method = $AUTOLOAD ) =~ s/.*:://;

   # Creating
   if ( grep ( /$method/, @OS::Common::Config::CMD ) )
   {
my $func = <<EOF
      sub OS::Common::OsTool::$method {
         my \$rc = oscmd( '$method', \@_ );
         if( \$rc != 0 )
         {
            Die( [ 'OS $method failed!', getErrors() ])
               if \$DieOnErrors;
            return \$rc;
         }
         else
         {
            return \$rc;
         }
      }
EOF
;
      eval( $func );
      Die( [$func, $@ ] ) if $@;

      goto &$AUTOLOAD;
   }
   else
   {
      # HARD ERROR
      confess "Could not create $AUTOLOAD";
   }

} # AUTOLOAD



my $CMD_RC;
my @CMD_OUTPUT;
my @CMD;

use vars qw( @SH_ERRORS @SH_WARNINGS @SH_OUTPUT %SH_RC $SH $SH_RT);

sub disableErrorStop
  {
    $DieOnErrors = 0;
}

sub enableErrorStop
  {
    $DieOnErrors = 1;
}

sub oscmd
  {

    @SH_ERRORS = ();
    @SH_WARNINGS = ();
    @SH_OUTPUT = ();
    %SH_RC = ();

    my @cmd = ();
    my $background = 0;

    if( $_[1] =~ m/^REMOTEHOST:(\S+)/ and $_[2] =~ m/^BACKGROUND$/ )
      {
        # the command to be executed on the remote host
        # shall be executed in the background, but not
        # the ssh command itself. Therefore we use
        # the nohup command to ensure that after logoff
        # of ssh the command continues execution.
	$_[1] =~ s/^REMOTEHOST:(\S+)/$1/;
	push @cmd, "ssh -n -q $_[1]";
	my $cmd = shift @_;
	if(defined( $OS::Common::Config::path{ $cmd } ))
	  {
	    $cmd = $OS::Common::Config::path{ $cmd } . $cmd;
	  }
	push @cmd, "\"nohup $cmd";
	shift @_;
	shift @_;
	push @cmd, @_;
	push @cmd, "&\"";
	$background = 1;
      }
    elsif( $_[1] =~ m/^REMOTEHOST:(\S+)/ )
      {
	push @cmd, "ssh -n -q $1";
	my $cmd = shift @_;
	if(defined( $OS::Common::Config::path{ $cmd } ))
	  {
	    $cmd = $OS::Common::Config::path{ $cmd } . $cmd;
	  }
	push @cmd, $cmd;
	shift @_;
	push @cmd, @_;
      }
    elsif( $_[1] =~  m/^BACKGROUND$/ )
      {
	my $cmd = shift @_;
	if(defined( $OS::Common::Config::path{ $cmd } ))
	  {
	    $cmd = $OS::Common::Config::path{ $cmd } . $cmd;
	  }
	push @cmd, $cmd;
	shift @_;
	push @cmd, @_;
	push @cmd, '&';
	$background = 1;
      }
    else
      {
	push @cmd, @_;
      }

# OLD code, used when commands will be executed by
# object of OS::Shell, what currently does not work.
#    %SH_RC = $SH->cmd( join( ' ', @cmd ));

   my $tmpout = POSIX::tmpnam();
   my $tmperr = POSIX::tmpnam();

    Exec( [ 'OS ' . join( ' ', @cmd )] );
    if( $background )
      {
	$SH_RT = system( "@cmd" );
	return 0;
      }
    $SH_RT = system( "@cmd 2>$tmperr 1>$tmpout" );

    open FD, "$tmpout" or Die( [ 'can not read temp file ' . $tmpout ] );
    my @tmp = <FD>;
    close FD;
    unlink $tmpout;
    foreach( @tmp )
      {
	if( /Warning/i )
	  {
	    push @SH_WARNINGS, $_;
	  }
	else
	  {
	    push @SH_OUTPUT, $_;
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
	    push @SH_WARNINGS, $_;
	  }
	else
	  {
	    push @SH_ERRORS, $_;
	  }
      }
    
    Debug( [ "OS RC ". $SH_RT ] );
    Debug( [ "OS Output", @SH_OUTPUT ] )
      if @SH_OUTPUT;
    Warn( [ "OS Warning", @SH_WARNINGS ] )
      if ( @SH_WARNINGS and $DieOnErrors );
    Error( [ "OS Errors", @SH_ERRORS ] )
      if ( @SH_ERRORS and $DieOnErrors);

    return ( $#SH_ERRORS > -1 );
} # zfscmd

sub registerRemoteHost
  {
    my $arrayRef = shift;
    my $hostname = shift;

    push @$arrayRef, 'REMOTEHOST:' . $hostname;
  }

sub registerBackground
  {
    my $arrayRef = shift;

    push @$arrayRef, 'BACKGROUND';
  }

sub getRC {
   return ( $SH_RT );
}

sub getErrors {
   return @SH_ERRORS if wantarray();
   return $#SH_ERRORS;
}

sub getWarnings {
   return @SH_WARNINGS if wantarray();
   return $#SH_WARNINGS;
}

sub getOutput {
   return @SH_OUTPUT if wantarray();
   return $#SH_OUTPUT;
}

1;

__END__

=head1 FILES

=head1 EXTERNAL INFLUENCES

=head1 EXAMPLES

=head1 WARNINGS

=head1 AUTHOR INFORMATION

 Copyright (C) 2009 Uwe Satthoff

=head1 CREDITS

=head1 BUGS

Address bug reports and comments to: satthoff@icloud.com

=head1 SEE ALSO

=cut
