package IPC::ChildSafe;

require 5.004;
use Carp;

require Exporter;
require DynaLoader;

$VERSION = '3.16';
# Exports are retained mostly for backward compatibility. Modern uses should
# (generally) employ the methods of the same name, e.g. $obj->store(1);
@EXPORT_OK = qw(NOTIFY STORE PRINT IGNORE);
@EXPORT = qw(CP_NO_SHOW_ERR CP_SHOW_ERR);
@ISA = qw(Exporter DynaLoader);

use strict;

use constant	NOTIFY => 0;	# default - print stderr msgs as they arrive
use constant	STORE  => 1;	# store stderr msgs for later retrieval
use constant	PRINT  => 2;	# send all output to screen immediately
use constant	IGNORE => 3;	# throw away all output, ignore retcode

use vars qw($VERSION $Debug_Level $No_Exec);

# An unusual situation - we allow the pure-Perl module to be installed
# successfully on Windows platforms without the related XS code. Not
# having the XS code means that IPC::ChildSafe cannot work - but
# its subclass IPC::ClearTool can since it replaces the methods
# which rely on the XS code anyway.
if ($^O !~ /win32|Windows_NT|cygwin/i) {
    # SWIG-generated XS code.
    bootstrap IPC::ChildSafe $IPC::ChildSafe::VERSION;
    var_ChildSafe_init();
}

# The current version and a way to access it.
sub version {$IPC::ChildSafe::VERSION}

# This is an undocumented service method, used only by the
# constructor. It's broken out to make it easier for the
# IPC::ClearTool module to override a minimal amount of code.
sub _open {
   my $self = shift;
   local $^W = 0;
   $self->{IPC_CHILD} = \child_open(@_);
   return $self;
}

########################################################################
# Constructor - this is just a layer over child_* (see childsafe.c
# and takes largely the same arguments.  We also allow an
# optional last arg which is a hash-ref containing miscellaneous params.
# This isn't published, it's really just a hack to allow the ClearTool
# subclass to work more smoothly. We also support, for backward compat,
# an initial mode and/or error discriminator here, but the modern/published
# interface is that these are set after construction via the appropriate
# methods. If no error discriminator is provided we use a default
# internal subroutine.
########################################################################
sub new {
   my $proto = shift;
   my $class = ref($proto) || $proto;
   my $cmd = shift;
   my $tag = shift;
   my $ret = shift;
   my($mode, $chk, $quit);

   # Hacks for backward compatibility with <2.33 versions
   if (ref($_[0]) eq 'HASH') {
      my %params = %{shift @_};
      local $^W = 0;
      $chk = $params{CHK};
      $mode = $params{MODE};
      $quit = $params{QUIT};
   } elsif (ref($_[0]) eq 'CODE') {
      $chk = shift;
   } elsif (@_) {
      $mode = shift;
      $chk = shift if @_;
   }

   # Initialize the hash which will represent this object.
   my $self  = {
      IPC_CHILD		=> undef,
      IPC_ERRCHK	=> undef,
      IPC_MODE		=> $mode || NOTIFY,
      IPC_STDOUT	=> [],
      IPC_STDERR	=> [],
   };
   bless ($self, $class);

   if ($chk) {
      $self->{IPC_ERRCHK} = $chk;
   } else {
      $self->{IPC_ERRCHK} = sub
	 {
	    my($r_stderr, $r_stdout) = @_;
	    grep(!/^\+\s|warning:/i, @$r_stderr);
	 };
   }

   $self->_open($cmd, $tag, $ret, $quit);

   @{$self->{IPC_STDOUT}} = ();
   @{$self->{IPC_STDERR}} = ();

   return $self;
}

# Unpublished - the guts that sends a command to the copro and
# sticks the results on the stacks. Separated from the 'cmd'
# method for the same reason give with _open() above.
sub _puts {
   my $self = shift;
   my $cmd = shift;

   # Send the command down to the child.
   child_puts($cmd, ${$self->{IPC_CHILD}},
		      $self->{IPC_STDOUT}, $self->{IPC_STDERR});
   return $self;
}

########################################################################
# Documented in PODs below.
########################################################################
sub cmd {
   my $self = shift;
   my($cmd, $mode, @junk) = @_;

   croak "extraneous data '@junk' follows command" if @junk;

   # If used in void context with no args, throw away all stored output.
   if (! $cmd) {
      croak "must provide a command line" if defined wantarray;
      $self->{IPC_STDOUT} = [];
      $self->{IPC_STDERR} = [];
      return;
   }

   # If the command will need to read input from stdin, provide
   # it here as a trailer so it's seen before the tag cmd. Yes,
   # it's a grievous hack.
   $cmd .= "\n$self->{IPC_STDIN}\n" if $self->{IPC_STDIN};

   # Send cmd, get back stdout/stderr in the IPC_STD(OUT|ERR) arrays.
   $self->_puts($cmd);

   # IPC_STDIN is a one-shot-use if present but don't delete it till here
   # in case _puts() (or an @ISA variant thereof) needs to reference it.
   delete $self->{IPC_STDIN};

   # This line should be self-documenting ... well, ok, we're
   # passing references to the stdout and stderr arrays into the
   # currently-registered discriminator function. The return value
   # is the number of errors it determined by examining
   # the output. Typically the discriminator only cares about the
   # stderr stream but we pass it stdout also in case it cares.
   $self->{IPC_STATUS} = int &{$self->{IPC_ERRCHK}}(\@{$self->{IPC_STDERR}},
					   \@{$self->{IPC_STDOUT}});

   # Now return different things depending on the context this
   # method was used in - see comment above for details.
   if (wantarray) {
      my $r_results = {
	 'stdout' => $self->{IPC_STDOUT},
	 'stderr' => $self->{IPC_STDERR},
	 'status' => $self->{IPC_STATUS},
      };
      $self->{IPC_STDOUT} = [];
      $self->{IPC_STDERR} = [];
      return %$r_results;
   } else {
      $mode ||= $self->{IPC_MODE};
      if ($mode == NOTIFY) {
	 $self->stderr;
      } elsif ($mode == PRINT) {
	 $self->stdout;
	 $self->stderr;
      } elsif ($mode == IGNORE) {
	 $self->{IPC_STDOUT} = [];
	 $self->{IPC_STDERR} = [];
      }
      if (!defined(wantarray) && ($mode != IGNORE) && $self->{IPC_STATUS}) {
	  warn __FILE__ . ": exit(@{[$self->{IPC_STATUS}]}) due to void context"
					    if $IPC::ChildSafe::Debug_Level;
	  exit $self->{IPC_STATUS};
      }
      return $self->{IPC_STATUS};
   }
}

sub stdin {
    my $self = shift;
    chomp($self->{IPC_STDIN} = "@_") if @_;
    return $self->{IPC_STDIN};
}

########################################################################
# Auto-generate methods to set the output-handling mode.
########################################################################
for my $mode (qw(NOTIFY STORE PRINT IGNORE)) {
   my $meth = lc $mode;
   no strict 'refs';
   *$meth = sub {
       my $self = shift;
       $self->{IPC_MODE} = (defined($_[0]) && !$_[0]) ? 0 : &$mode;
       $self;
   };
}

########################################################################
# Documented in PODs below.
########################################################################
sub status {
   my $self = shift;
   return int &{$self->{IPC_ERRCHK}}($self->{IPC_STDERR}, $self->{IPC_STDOUT});
}

########################################################################
# Documented in PODs below.
########################################################################
sub stdout {
   my $self = shift;
   return 0 unless $self->{IPC_STDOUT};
   if (wantarray) {
      my @out = @{$self->{IPC_STDOUT}};
      $self->{IPC_STDOUT} = [];
      return @out;
   } elsif (defined(wantarray)) {
      return @{$self->{IPC_STDOUT}};
   } else {
      print STDOUT @{$self->{IPC_STDOUT}};
      $self->{IPC_STDOUT} = [];
   }
}

########################################################################
# Documented in PODs below.
########################################################################
sub stderr {
   my $self = shift;
   return 0 unless $self->{IPC_STDERR};
   if (wantarray) {
      my @errs = @{$self->{IPC_STDERR}};
      $self->{IPC_STDERR} = [];
      return @errs;
   } elsif (defined(wantarray)) {
      return @{$self->{IPC_STDERR}};
   } else {
      print STDERR @{$self->{IPC_STDERR}};
      $self->{IPC_STDERR} = [];
   }
}

########################################################################
# This method takes a reference to an error-checking subroutine and
# registers it to handle subsequent stderr output. It returns a
# reference to the superseded discriminator function.
########################################################################
sub errchk {
   my $self = shift;
   my $old_errchk = $self->{IPC_ERRCHK};
   $self->{IPC_ERRCHK} = shift if @_;
   return $old_errchk;
}

########################################################################
# Send a signal to the child process, which is in a different session.
########################################################################
sub kill {
   my $self = shift;
   my $signo = shift || 2;	# default is SIGINT (2)
   if ($signo !~ /^\d+$/) {
      require Config;
      $signo =~ s%^SIG%%i;
      my $i = 0;
      my %sigmap = map {$_ => $i++} split ' ', $Config::Config{sig_name};
      $signo = $sigmap{$signo};
   }
   my $status = child_kill(${$self->{IPC_CHILD}}, $signo);
   return $status;
}

########################################################################
# Shut down the child process and report its exit status.
########################################################################
sub finish {
   my $self = shift;
   my $status = child_close(${$self->{IPC_CHILD}});
   undef $self->{IPC_CHILD};
   return $status;
}

########################################################################
# Destructor - causes child process to be stopped when the last
# reference to its associated object goes away.
########################################################################
sub DESTROY {
   my $self = shift;
   $self->finish if $self->{IPC_CHILD};
}

########################################################################
# Set or change the current debugging level.  Each level implies those lower:
#   0 == no debugging output
#   1 == programmer-defined temporary debug output
#   2 == commands sent to the child process
#   3 == data returned from the child process
#   4 == all meta-data exchanged by parent and child: tag, ret, polling, etc.
# Other debug levels are unassigned and available for user definition.
## With no args, this method toggles state between no-debug and max-debug.
### Debug_Level is resident in the C code.
########################################################################
sub dbglevel {
   my $self = shift;
   if (@_) {
      $IPC::ChildSafe::Debug_Level = shift;
   } else {
      $IPC::ChildSafe::Debug_Level = $IPC::ChildSafe::Debug_Level ? 0 : -1>>1;
   }
   $self->{DBGLEVEL} = $IPC::ChildSafe::Debug_Level;
}

# Similar to dbglevel method. Modifies a class attribute in the C code.
sub noexec {
    my $self = shift;
    if (@_) {
	$IPC::ChildSafe::No_Exec = shift;
    } elsif (!defined wantarray) {
	$IPC::ChildSafe::No_Exec = 1;
    }
    $self->{NOEXEC} = $IPC::ChildSafe::No_Exec;
}

#   This is undocumented but such a horrible hack that it needs a comment.
# Win32::OLE seems to want to return its output in scalar form in some
# situations. So when using COM we have to split that scalar back into a
# list as required. Since we're certainly on Windows we can assume \cM\cJ
# as the line separator, but there's some awful stuff which has
# to be done to deal with trailing blank lines.
#   It may be that Win32::OLE would do the right thing when data is
# returned to a collection object and that may be the better thing to do.
# Haven't had a chance to try it yet.
#   The hack doesn't belong here - this module doesn't even KNOW about
# Win32::OLE or COM. However, at least two subclasses are known to need
# it so it's kept here to avoid having multiple copies.
if ($^O =~ /win32|Windows_NT|cygwin/i) {
    sub _fixup_COM_scalars {
	my($self, $line) = @_;
	return () if !defined $line;
	$line =~ s%\cM\cJ$%%s;
	my @lines = map {"$_\n"} split(m%\cM\cJ%, $line, -1);
	return @lines;
    }
}

1;

__END__

=head1 NAME

IPC::ChildSafe, ChildSafe - control a child process without blocking

=head1 SYNOPSIS

   use IPC::ChildSafe;

   # Start a shell process (create a new shell object).
   $SH = IPC::ChildSafe->new('sh', 'echo ++EOT++', '++EOT++');

   # If the ls command succeeds, read lines from its stdout one at a time.
   if ($SH->cmd('ls') == 0) {
      print "Found ", scalar($SH->stdout), " files in current dir ...\n";

      # Another ls cmd - results added to the object's internal stack
      $SH->cmd('ls /tmp');

      # Since we're stuck in this dumb example, let's get the date too.
      $SH->cmd('date');

      # Now dump results to stdout - show how to get 1 line at a time
      for my $line ($SH->stdout) {
	 print $line;
      }

      # You could also print the output this way:
      # print $SH->stdout;

      # Or even just:
      # $SH->stdout;

   }

   # Send it a command, read back the stdout/stderr/return code
   # into a hash array.
   my(%results) = $SH->cmd('id');		# Send an 'id' cmd
   die if $results{status};			# Expect no errors
   die if @{$results{stdout}} != 1;		# Should be just 1 line
   die if $results{stdout}[0] !~ /^uid=/;	# Check output line

   # (lather, rinse, repeat)

   # Finishing up.
   die if $SH->finish;				# Returns final status

=head1 DESCRIPTION

   This was written to address the "blocking problem" inherent in
most coprocessing designs such as IPC::Open3.pm, which has warnings
such as this in its documentation:

    ... additionally, this is very dangerous as you may block forever.  It
   assumes it's going to talk to something like bc, both writing to it and
   reading from it.  This is presumably safe because you "know" that
   commands like bc will read a line at a time and output a line at a
   time ...

or IPC::Open2 which has this warning from its author (Tom Christansen):

   ... I strongly advise against using open2 for almost anything, even
   though I'm its author. UNIX buffering will just drive you up the wall.
   You'll end up quite disappointed ...

The blocking problem is: once you've sent a command to your coprocess,
how do you know when the output resulting from this command has
finished?  If you guess wrong and issue one read too many you can
deadlock forever.  This implementation solves the problem, at least for
a subset of possible child programs, by using a little trick:  it sends
a 2nd (trivial) command down the pipe right in back of every real
command.  When we see the the output of this special command in the
return pipe, we know the real command is done.

This module also returns an "exit status" for each command, which is
really a count of the error messages produced by it.  The programmer
can optionally register his/her own discriminator function for
determining which output to stderr constitutes an error message.

=head1 CONSTRUCTOR

The constructor takes 3 arguments plus an optional 4th and 5th: the 1st
is the program to run, the 2nd is a command to that program which
produces a unique one-line output, and the 3rd is that unique output.
If a 4th arg is supplied it becomes the mode in which this object will
run (default: NOTIFY, see below), and if a 5th is given it must be a
code ref, which will be registered as the error discriminator.  If no
discriminator is supplied then a standard internal one is used.

The 2nd arg is called the "tag command". Preferably this would be
something lightweight, e.g. a shell builtin. Unfortunately the current
version has no support for a multi-line return value since it would
require some fairly complex buffering.

=head1 DISCRIMINATOR

The discriminator function is invoked after each command completes, and
is passed a reference to an array containing the stderr generated by
that command in its first parameter. A pointer to the stdout is
similarly supplied in the second param. Normally this function would
just apply a regular expression to one or both of these and indicate by
its return status whether it considers this to constitute an error
condition. E.g. the version provided internally is:

    sub errors {
	my($r_stderr, $r_stdout) = @_;
	grep(!/^\+\s|warning:/i, @$r_stderr);
    }

which treats ANY output to stderr as indicative of an error, with the
exception of lines beginning with "+ " (shell verbosity) or containing
the string "warning:".

=head1 METHODS

=over 4

=item * B<notify/store/print/ignore>

Sets the output-handling mode. The meanings of these are described
below.

=item * B<cmd>

Send specified command to child process. Return behavior varies
with context:

=over 4

=item array context

returns a hash containing an array of stdout results (key: 'stdout'),
an array of stderr messages ('stderr), and the "return code" of the
command ('status').

=item scalar context

returns command's "return code".  In the default mode (NOTIFY), sends
stderr results directly to parent's stderr while storing stdout in the
object for later retrieval via I<stdout> method. In PRINT mode both
stdout and stderr are sent directly to the "real" (parent's)
stdout/stderr. STORE mode causes both stdout and stderr to be stored
for later use, while IGNORE mode throws away both.

=item void context

similar to scalar mode but exits on nonzero return code unless in
IGNORE mode.

=item void context and no args

clears the stdout and stderr buffers

=back

=item * B<stdout>

Return stored output from previous command(s). Behavior varies with
context:

=over 4

=item array context

shifts all stored lines off the stdout stack and returns them in a list.

=item scalar context

returns the number of lines currently stored in the stdout stack.

=item void context

prints the current stdout stack to actual stdout.

=back

=item * B<stderr>

Similar to C<stdout> method above. Note that by default stderr does
not go to the accumulator, but rather to the parent's stderr.  Set the
STORE attribute to leave stderr in the accumulator instead where this
method can operate on it.

=item * B<status>

Pass the current stdout and stderr buffers to the currently-registered
error discriminator and return its results (aka the error count).

=item * B<kill>

Sends an interrupt signal to the child process.  If you've installed a
signal handler in the parent using %SIG, you can use -E<gt>kill to stop
the command I<currently> running in the child from within the handler,
then continue to use the child for potential cleanup operations before
shutting down.

A signal other than SIGINT (aka Ctrl-C) may be sent by specifing its
name, e.g.
	
    $child->kill('HUP');

However, note that signal handling is very complex. The only code path
tested is that of SIGINT and other signals may have unpredictable
results. Even with SIGINT, a great deal depends on how the tool running
as the child process handles it.

=item * B<finish>

Ends the child process and returns its final exit status.

=item * B<dbglevel>

Sets a debugging (verbosity) level. Current defined levels are 1-4.
Verbosity lines are printed with a leading '+'.

=item * B<noexec>

Sets the 'noexec' attribute, which causes commands to not be run but to
be printed with a leading '-'.

=back

=head1 AUTHOR

David Boyce dsbperl@cleartool.com

Copyright (c) 1997-2001 David Boyce. All rights reserved. This perl
program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), "perldoc IPC::Open3", _Advanced Programming in the Unix Environment_
by W. R. Stevens

=cut
