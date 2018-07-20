package IPC::ClearTool;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);

BEGIN {
    if ($^O =~ /win32|Windows_NT|cygwin/i) {
	require Win32::OLE;
    }
}

use IPC::ChildSafe 3.15;
@EXPORT_OK = @IPC::ChildSafe::EXPORT_OK;
%EXPORT_TAGS = ( BehaviorMod => \@EXPORT_OK );
@ISA = q(IPC::ChildSafe);

# The current version and a way to access it.
$VERSION = "3.16"; sub version {$VERSION}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    if ($^O =~ /win32|Windows_NT|cygwin/i) {
	return $class->SUPER::new(@_);
    }

    my $ct = join('/', $ENV{ATRIAHOME} || '/usr/atria', 'bin/cleartool');
    $ct = 'cleartool' unless -x $ct;
    my $chk = sub {
	my($r_stderr, $r_stdout) = @_;
	return int grep /Error:\s/, @$r_stderr;
    };
    my %params = ( QUIT => 'exit', CHK => $chk );
    my $self = $class->SUPER::new($ct, 'pwd -h', 'Usage: pwd', \%params);
    bless ($self, $class);
    return $self;
}

sub comment {
    my $self = shift;
    my $cmnt = shift;
    $self->stdin("$cmnt\n.");
    return $self;
}

sub chdir {
    my $self = shift;
    my $nwd = shift;
    if (!CORE::chdir($nwd)) {
	warn "$nwd: $!\n";
	return 0;
    }
    if ($^O =~ /win32|Windows_NT|cygwin/i) {
	return $self->cmd(qq(cd $nwd));
    } else {
	return $self->cmd(qq(cd "$nwd"));
    }
}
*cd = *chdir;

sub _open {
    my $self = shift;
    if ($^O =~ /win32|Windows_NT|cygwin/i) {
	$self->{IPC_CHILD} = Win32::OLE->new('ClearCase.ClearTool')
			|| die "Cannot create ClearCase.ClearTool object\n";
	Win32::OLE->Option(Warn => 0);
	return $self;
    }
    return $self->SUPER::_open(@_);
}

sub _puts {
    my $self = shift;
    if ($^O =~ /win32|Windows_NT|cygwin/i) {
	my $cmd = shift;
	my $dbg = $self->{DBGLEVEL} || 0;
	warn "+ -->> $cmd\n" if $dbg;
	my $out = $self->{IPC_CHILD}->CmdExec($cmd);
	# CmdExec always returns a scalar through Win32::OLE so
	# we have to split it in case it's really a list.
	if ($out) {
	    my @stdout = $self->_fixup_COM_scalars($out);
	    push(@{$self->{IPC_STDOUT}}, @stdout);
	    print STDERR map {"+ <<-- $_"} @stdout if $dbg > 1;
	}
	if (my $err = Win32::OLE->LastError) {
	    $err =~ s/OLE exception from.*?:\s*//;
	    my @stderr = $self->_fixup_COM_scalars($err);
	    @stderr = grep !/Unspecified error/is, @stderr;
	    print STDERR map {"+ <<== $_"} @stderr if $dbg > 1;
	    push(@{$self->{IPC_STDERR}},
			    map {"cleartool: Error: $_"} @stderr);
	}
	return $self;
    } else {
	return $self->SUPER::_puts(@_);
    }
}

sub finish {
    my $self = shift;
    if ($^O =~ /win32|Windows_NT|cygwin/i) {
	undef $self->{IPC_CHILD};
	return 0;
    }
    return $self->SUPER::finish(@_);
}

# Hack to propagate these old, deprecated names for back-compat.
*NOTIFY = *IPC::ChildSafe::NOTIFY;
*STORE  = *IPC::ChildSafe::STORE;
*PRINT  = *IPC::ChildSafe::PRINT;
*IGNORE = *IPC::ChildSafe::IGNORE;

1;

__END__

=head1 NAME

IPC::ClearTool, ClearTool - run a bidirectional pipe to a cleartool process

=head1 SYNOPSIS

  use IPC::ClearTool;

  my $CT = IPC::ClearTool->new;
  $CT->cmd("pwv");
  $CT->cmd("lsview");
  $CT->cmd("lsvob -s");
  for ($CT->stdout) { print }
  $CT->finish;

=head1 ALTERNATE SYNOPSES

  use IPC::ClearTool;

  $rc = $CT->cmd("pwv");		# Assign return code to $rc

  $CT->notify;				# "notify mode" is default;
  $rc = $CT->cmd("pwv");		# same as above

  $CT->store;				# "Store mode" - hold stderr for
  $rc = $CT->cmd("pwv -X");		# later retrieval via $CT->stderr
  @errs = $CT->stderr;			# Retrieve it now

  $CT->ignore;				# Discard all stdout/stderr and
  $CT->cmd("pwv");			# ignore nonzero return codes

  $CT->cmd("ls foo@@");			# In void context, store stdout,
					# print stderr immediately,
					# exit on error.

  my %results = $CT->cmd("pwv");	# Place all results in %results,
					# available as:
					#   @{$results{stdout}}
					#   @{$results{stderr}}
					#   @{$results{status}}

  $CT->cmd();				# Clear all accumulators

  $CT->stdout;				# In void context, print stored output

=head1 DESCRIPTION

This module invokes the ClearCase 'cleartool' command as a child
process and opens pipes to its standard input, output, and standard
error. Cleartool commands may be sent "down the pipe" via the
$CT-E<gt>cmd() method.  All stdout resulting from commands is stored in
the object and can be retrieved at any time via the $CT-E<gt>stdout
method. By default, stderr from commands is sent directly to the C<real>
(parent's) stderr but if the I<store> attribute is set as shown above,
stderr will accumulate just like stdout and must be retrieved via
C<$CT-E<gt>stderr>.

If $CT-E<gt>cmd is called in a void context it will exit on error
unless the I<ignore> attribute is set, in which case all output is
thrown away and error messages suppressed.  If called in a scalar
context it returns the exit status of the command. In a list context
it returns a hash containing keys C<stdout>, C<stderr>, and <status>.

When used with no arguments and in a void context, $CT-E<gt>cmd simply
clears the stdout and stderr accumulators.

The $CT-E<gt>stdout and $CT-E<gt>stderr methods behave much like
arrays; when used in a scalar context they return the number of lines
currently stored.  When used in a list context they return an
array containing all currently stored lines, and then clear the
internal stack.

The $CT-E<gt>finish method ends the child process and returns its exit
status.

This is only a summary of the documentation. There are more advanced
methods for error detection, data return, etc. documented as part of
IPC::ChildSafe. Note that IPC::ClearTool is simply a small subclass of
ChildSafe; it provides the right defaults to the constructor for
running cleartool and adds a few ClearCase-specific methods. In other
ways it's identical to ChildSafe, and all ChildSafe documentation
applies.

=head1 BUGS

=over 4

=item * Comments

Comments present a special problem. If a comment is prompted for, it
will likely hang the child process by interrupting the tag/eot
sequencing. So we prefer to pass comments on the command line with C<-c>.
Unfortunately, the quoting rules of cleartool are insufficient to allow
passing comments with embedded newlines using C<-c>. The result being
that there's no clean way to handle multi-line comments.

To work around this, a method C<$CT-E<gt>comment> is provided which
registers a comment I<to be passed to the next C<$CT-E<gt>cmd()> command>.
It's inserted into the stdin stream with a "\n.\n" appended.
The subsequent command must have a C<-cq> flag, e.g.:

    $CT->comment("Here's a\nmultiple line\ncomment");
    $CT->cmd("ci -cq foo.c");

If your script hangs and the comment for the last element checked in is
C<"pwd -h">, then you were burned by such a sync problem.

=item * UNIX/Win32 Semantics Skew

On UNIX, this module works by running cleartool as a child process.  On
Windows, the ClearCase Automation Library (a COM API) is used instead.
This provides the same interface B<but be warned that there's a subtle
semantic difference!> On UNIX you can send a setview command to the
child and it will run in the new view while the parent's environment
remains unchanged. On Windows there's no subprocess; thus the setview
would change the context of the "parent process".  The same applies to
chdir commands. It's unclear which behavior is "better" overall, but in
any case portable applications must take extra care in using such
stateful techniques.

As a partial remedy, a C<chdir> method is provided. This simply does
the C<cd> in both parent and child processes in an attempt to emulate
the in-process behavior. Emulating an in-process C<setview> is harder
because on UNIX, setview is implemented with a fork/chroot/exec
sequence so (a) it's hard to know how a single-process setview
I<should> behave and (b) I wouldn't know how to do it anyway,
especially lacking the privileges required by chroot(2). Of course
in most cases you could work around this by using C<chdir> to work
in view-extended space rather than a set view.

In some cases the ability to set the child process into a different
view or directory is a feature so no attempt is made to stop you from
doing that.

=item * Win32::OLE Behavior with IClearTool

Due to the way Win32::OLE works, on Windows the results of each
command are passed back as a single string, possibly with embedded
newlines. For consistency, in a list context we split this back into
lines and return the list.

=back

=head1 AUTHOR

David Boyce dsbperl@cleartool.com

Copyright (c) 1997-2002 David Boyce. All rights reserved. This perl
program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), "perldoc IPC::ChildSafe"

=cut
