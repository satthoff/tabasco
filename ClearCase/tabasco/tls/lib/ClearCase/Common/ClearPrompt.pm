package ClearCase::Common::ClearPrompt;

require 5.001;

$VERSION = $VERSION = '1.24';
@EXPORT_OK = qw(clearprompt clearprompt_dir redirect tempname die
		$CT $TriggerSeries
);

%EXPORT_TAGS = ( 'all' => [ qw(
	clearprompt
	clearprompt_dir
	redirect
	tempname
) ] );

require Exporter;
@ISA = qw(Exporter);

# Conceptually this is "use constant MSWIN ..." but ccperl can't do that.
sub MSWIN { ($^O || $ENV{OS}) =~ /MSWin32|Windows_NT/i }

use vars qw($TriggerSeries $StashFile);
$TriggerSeries = $ENV{CLEARCASE_CLEARPROMPT_TRIGGERSERIES};

# Make $CT read-only but not a constant so it can be interpolated.
*CT = \ccpath('cleartool');

if ($] > 5.004) {
    use strict;
    eval "use subs 'die'";  # We override this and may also export it to caller
}

my %MailTo = (); # accumulates lists of users to mail various msgs to.

(my $prog = $0) =~ s%.*[/\\]%%;

# Fork a shell if requested via this EV. Very useful in triggers because
# it lets you explore the runtime environment of the trigger script.
if ($ENV{CLEARCASE_CLEARPROMPT_DEBUG_SHELL} && !$ENV{PERL_DL_NONLAZY}) {
    my $cmd = MSWIN() ? $ENV{COMSPEC} : '/bin/sh';
    $cmd = $ENV{CLEARCASE_CLEARPROMPT_DEBUG_SHELL}
				if -x $ENV{CLEARCASE_CLEARPROMPT_DEBUG_SHELL};
    exit 1 if system $cmd;
}

# Make an attempt to supply a full path to the specified program.
# Else fall back to relying on PATH.
sub ccpath {
    my $name = shift;
    if (MSWIN()) {
	return $name;	# no way to avoid relying on PATH in &^&@$! Windows
    } else {
	return join('/', $ENV{ATRIAHOME} || q(/usr/atria), 'bin', $name);
    }
}

# Generates a random-ish name for a temp file that doesn't yet exist.
# This function makes no pretense of being atomic; it's conceivable,
# though highly unlikely, that the generated filename could be
# taken between the time it's generated and the time it's used.
# The optional parameter becomes a filename extension. The optional
# 2nd parameter overrides the basename part of the generated path.
sub tempname {
    my($custom, $tmpf) = @_;
    # The preferred directory for temp files.
    my $tmpd = MSWIN() ?
	    ($ENV{TEMP} || $ENV{TMP} || ( -d "$ENV{SYSTEMDRIVE}/temp" ?
			      "$ENV{SYSTEMDRIVE}/temp" : $ENV{SYSTEMDRIVE})) :
	    ($ENV{TMPDIR} || '/tmp');
    $tmpd =~ s%\\%/%g;
    my $ext = 'tmp';
    return "$tmpd/$tmpf.$custom.$ext" if $tmpf;
    (my $pkg = lc __PACKAGE__) =~ s/:+/-/g;
    while (1) {
	$tmpf = join('.', "$tmpd/$pkg", $$, int(rand 10000));
	$tmpf .= $custom ? ".$custom.$ext" : ".$ext";
	return $tmpf if ! -f $tmpf;
    }
}

# Run clearprompt with specified args and return what it returned. Uses the
# exact same syntax as the clearprompt executable ('ct man clearprompt')
# except for -outfile <file> which is handled internally here.
sub clearprompt {
    my $mode = shift;
    my @args = @_;
    my $data;

    return 0 if $ENV{ATRIA_WEB_GUI};	# must assume "" or 0 if ccweb interface

    local $!;	# don't mess up errno in the caller's world.

    # Play back responses from the StashFile if it exists and other conditions
    # are satisfied. It seems that CC sets the series id to all zeroes
    # after an error condition (??) so we avoid that case explicitly.
    my $lineno = (caller)[2];
    if ($TriggerSeries && $ENV{CLEARCASE_SERIES_ID} &&
				    $ENV{CLEARCASE_SERIES_ID} !~ /^[0:.]+$/) {
	(my $sid = $ENV{CLEARCASE_SERIES_ID}) =~ s%:+%-%g;
	$StashFile = tempname($prog, "CLEARCASE_SERIES_ID=$sid");
	if (!$ENV{CLEARCASE_BEGIN_SERIES} && -f $StashFile) {
	    do $StashFile;
	    if ($ENV{CLEARCASE_END_SERIES}) {
		# We delay the unlink due to weird  Windows locking behavior
		eval "END { unlink '$StashFile' }";
	    }
	    no strict 'vars';
	    return eval "\$stash$lineno";
	}
    }

    # On Windows we must add an extra level of escaping to any args
    # which might have special chars since all forms of system()
    # appear to go through the %^%@# cmd shell (boo!).
    if (MSWIN()) {
	for (0..$#args) {
	    my $i = $_;
	    if ($args[$i] =~ /^-(?:pro|ite|def|dfi|dir)/) {
		$args[$i+1] =~ s/"/'/gs;
		$args[$i+1] = qq("$args[$i+1]");
	    }
	}
    }

    # For clearprompt modes in which we get textual data back via a file,
    # derive here a reasonable temp-file name and handle the details
    # of reading the data out of it and unlinking it when done.
    # For other modes, just fire off the cmd and return the status.
    # In a void context, don't wait for the button to be pushed; just
    # "fork" and proceed asynchonously since this is presumably just an
    # informational message.
    # If the cmd took a signal, return undef and leave the signal # in $?.
    if ($mode =~ /text|file|list/) {
	my $outf = tempname($mode);
	my @cmd = (ccpath('clearprompt'), $mode, '-out', $outf, @args);
	print STDERR "+ @cmd\n" if $ClearCase::Common::ClearPrompt::Verbose;
	if (!system(@cmd)) {
	    if (open(OUTFILE, $outf)) {
		local $/ = undef;
		$data = <OUTFILE>;
		$data = '' if !defined $data;
		close(OUTFILE);
	    }
	} else {
	    # If we took a signal, return undef with the signal # in $?. The
	    # clearprompt cmd apparently catches SIGINT and returns 0x400 for
	    # some reason; we fix it here so $? looks like a normal sig2.
	    $? = 2 if $? == 0x400;
	    $data = undef if $? && $? <= 0x80;
	}
	unlink $outf if -f $outf;
    } else {
	my @cmd = (ccpath('clearprompt'), $mode, @args);
	print STDERR "+ @cmd\n" if $ClearCase::Common::ClearPrompt::Verbose;
	if (defined wantarray) {
	    system(@cmd);
	    $? = 2 if $? == 0x400;  # see above
	    $data = ($? && $? <= 0x80) ? undef : $?>>8;
	} else {
	    if (MSWIN()) {
		system(1, @cmd);
		return;
	    } else {
		return if fork;
		exec(@cmd);
	    }
	}
    }

    # Record responses if $TriggerSeries is turned on.
    if ($StashFile) {
	if ($ENV{CLEARCASE_BEGIN_SERIES} && !$ENV{CLEARCASE_END_SERIES}) {
	    require Data::Dumper;
	    open(STASH, ">>$StashFile") || die "$prog: $StashFile: $!";
	    print STASH "# This file contains data stashed for $prog\n";
	    print STASH Data::Dumper->new([$data], ["stash$lineno"])->Dump;
	    close(STASH);
	    $SIG{INT} = sub { unlink $StashFile };
	}
    }

    return $data;
}

# Fake up a directory chooser using opendir/readdir/closedir and
# 'clearprompt list'.
sub clearprompt_dir {
    require Cwd;
    require File::Spec;
    my($dir, $msg) = @_;
    my(%subdirs, $items, @drives);
    my $iwd = Cwd::abs_path('.');
    $dir = $iwd if $dir eq '.';

    return 0 if $ENV{ATRIA_WEB_GUI};	# must assume "" or 0 if ccweb interface

    while (1) {
	if (opendir(DIR, $dir)) {
	    %subdirs = map {$_ => 1} grep {-d "$dir/$_" || ! -e "$dir/$_"}
								readdir(DIR);
	    chomp %subdirs;
	    closedir(DIR);
	} else {
	    warn "$dir: $!\n";
	    $dir = File::Spec->rootdir;
	    next;
	}
	if (MSWIN() && $dir =~ m%^[A-Z]:[\\/]?$%i) {
	    delete $subdirs{'.'};
	    delete $subdirs{'..'};
	    @drives = grep {-e} map {"$_:"} 'C'..'Z' if !@drives;
	    $items = join(',', @drives, sort keys %subdirs);
	} else {
	    $items = join(',', sort keys %subdirs);
	}
	my $resp = clearprompt(qw(list -items), $items,
						    '-pro', "$msg  [ $dir ]");
	if (!defined $resp) {
	    undef $dir;
	    last;
	}
	chomp $resp;
	last if ! $resp || $resp eq '.';
	if (MSWIN() && $resp =~ m%^[A-Z]:[\\/]?$%i) {
	    $dir = $resp;
	    chdir $dir || warn "$dir: $!\n";
	} else {
	    $dir = Cwd::abs_path(File::Spec->catdir($dir, $resp));
	}
    }
    chdir $iwd || warn "$iwd: $!\n";
    return $dir;
}

# Takes args in the form "redirect(STDERR => 'OFF', STDOUT => 'ON')" and
# enables or disables stdout/stderr as specified.
sub redirect {
    # Stash these away at first use for potential future use, e.g. debugging.
    open(SAVE_STDOUT, '>&STDOUT') if !defined fileno(SAVE_STDOUT);
    open(SAVE_STDERR, '>&STDERR') if !defined fileno(SAVE_STDERR);

    while(@_) {
	my $stream = uc shift;
	my $state  = shift;

	if ($stream ne 'STDOUT' && $stream ne 'STDERR') {
	    print SAVE_STDERR "unrecognized stream $stream\n";
	    next;
	}

	if ($stream eq 'STDOUT') {
	    if ($state =~ /^OFF$/i) {
		if (defined fileno(STDOUT)) {
		    open(HIDE_STDOUT, '>&STDOUT')
					    if !defined fileno(HIDE_STDOUT);
		    close(STDOUT);
		}
	    } elsif ($state =~ /^ON$/i) {
		open(STDOUT, '>&HIDE_STDOUT');
	    } else {
		if (defined fileno(STDOUT)) {
		    open(HIDE_STDOUT, '>&STDOUT')
					    if !defined fileno(HIDE_STDOUT);
		    open(STDOUT, $state) || warn "$state: $!\n";
		}
	    }
	} elsif ($stream eq 'STDERR') {
	    if ($state =~ /^OFF$/i) {
		if (defined fileno(STDERR)) {
		    open(HIDE_STDERR, '>&STDERR')
					    if !defined fileno(HIDE_STDERR);
		    close(STDERR);
		}
	    } elsif ($state =~ /^ON$/i) {
		open(STDERR, '>&HIDE_STDERR');
	    } else {
		if (defined fileno(STDERR)) {
		    open(HIDE_STDERR, '>&STDERR')
					    if !defined fileno(HIDE_STDERR);
		    open(STDERR, $state) || warn "$state: $!\n";
		}
	    }
	}
    }
}

# Called like this "sendmsg([<to-list>], $subject, @body_of_message)".
# I.e. a ref to a list of email addresses followed by a string
# scalar containing the subject. Remaining parameters are used
# as the body of the message. Returns true on successful delivery
# of msg to the MTA; subsequent delivery is not guaranteed.
sub sendmsg {
    my($r_to, $subj, @body) = @_;
    # If no mailto list, no mail.
    return 0 unless @$r_to;
    # Only drag Net::SMTP in at runtime since it's not core perl.
    eval { require Net::SMTP };
    return $@ if $@;
    my $smtp = Net::SMTP->new;	# assumes Net::SMTP Config.pm is set up right
    return 2 unless defined $smtp;
    local $^W = 0; # hide a spurious warning - from deep in Net::SMTP maybe??
    $smtp->mail($ENV{CLEARCASE_USER} || $ENV{USERNAME} || $ENV{LOGNAME}) &&
	$smtp->to(@$r_to, {SkipBad => 1}) &&
	$smtp->data() &&
	$smtp->datasend("To: @$r_to\n") &&
	$smtp->datasend("Subject: $subj\n") &&
	$smtp->datasend("X-Mailer: $prog\n") &&
	$smtp->datasend("\n") &&
	$smtp->datasend(@body) &&
	$smtp->dataend() &&
	$smtp->quit;
}

# A private wrapper over sendmsg() to reformat the subj/msg
# appropriately for error message captures.
sub _automail {
   return 0 if defined $ENV{CLEARCASE_CLEARPROMPT_NO_SENDMSG};
   my $type = shift;
   my $addrs = shift;
   return unless $addrs;
   my $subj = shift;
   # We don't need Sys::Hostname except in this situation, so ...
   eval { require Sys::Hostname; };
   $subj .= ' on ' . Sys::Hostname::hostname() . ' via ' . __PACKAGE__;
   return sendmsg($addrs, $subj, @_);
}

# Warning: significant hackery here. Basically, normal-looking symbol
# names are passed on to the Exporter import method as usual, whereas
# names of the form +WORD or +WORD=<list> are commands which produce
# special behavior within this import sub. All commands start with
# '+' and include +{CAPTURE,ERRORS,WARN,DIE,STDOUT,STDERR}. If the cmd
# name has a list of users attached, eg "+STDERR=user1,user2,..",
# this leaves the channel attached and also mails messages to the
# specified users. Use +CAPTURE=<list> to email messages from all channels
# to <list>.
sub import {
    # First remember the entire parameter list.
    my @p = @_;

    # Then separate it into "normal-looking" symbols to export into
    # caller's namespace and "commands" to deal with right here.
    # Also, provide our own implementation of export tags for qw(:all).
    # I'd prefer not to support that any more but must for back compat.
    my %exports = map { $_ => 1 } grep !/^[+:]/, @p;
    my @tags = map {substr($_, 1)} grep /^:/, @p;
    my %cmds = map {m%^.(\w+)=?(.*)%; $1 => $2 } grep /^\+/, @p;

    # If :tags were requested, map them to their predefined export lists.
    for (@tags) {
	my $tag = $_;
	next unless $EXPORT_TAGS{$tag};
	for (@{$EXPORT_TAGS{$tag}}) {
	    $exports{$_} = 1;
	}
    }

    # Export the die func if its corresponding channel was requested.
    $exports{'die'} = 1 if exists $cmds{DIE};

    # Export the non-cmd symbols, which may include die().
    my @shares = grep {!/:/} keys %exports;
    if ($] <= 5.001) {
	# This weird hackery needed for ccperl (5.001) ...
	my $caller = caller;
	$caller = 'main' if $caller eq 'DB';	# hack for ccperl -d bug
	for (@shares) {
	    if (s/^(\W)//) {
		eval "*{$caller\::$_} = \\$1$_";
	    } else {
		*{"$caller\::$_"} = \&$_;
	    }
	}
    } else {
	# ... and this "normal" hackery is for modern perls.
	__PACKAGE__->export_to_level(1, $p[0], @shares);
    }

    # Allow this EV to override the capture list.
    if ($ENV{CLEARCASE_CLEARPROMPT_CAPTURE_LIST}) {
	%cmds = map {m%^.(\w+)=?(.*)%; $1 => $2 } grep /^\+/,
			split /\s+/, $ENV{CLEARCASE_CLEARPROMPT_CAPTURE_LIST};
    }

    # Allow trigger series stashing to be turned on at import time,
    # but let the EV override.
    $ClearCase::Common::ClearPrompt::TriggerSeries = 1 if exists $cmds{TRIGGERSERIES}
			&& !exists $ENV{CLEARCASE_CLEARPROMPT_TRIGGERSERIES};

    # +CAPTURE grabs all forms of output while +ERRORS grabs only error
    # forms (meaning everything but stdout). NOTE: we must be very careful
    # about the fact that %cmds may have keys which EXIST but whose
    # values are UNDEFINED.
    if (exists($cmds{CAPTURE})) {
	$cmds{WARN}	||= $cmds{CAPTURE};
	$cmds{DIE}	||= $cmds{CAPTURE};
	$cmds{STDERR}	||= $cmds{CAPTURE};
	$cmds{STDOUT}	||= $cmds{CAPTURE};
	delete $cmds{CAPTURE};
    } elsif (exists($cmds{ERRORS})) {
	$cmds{WARN}	||= $cmds{ERRORS};
	$cmds{DIE}	||= $cmds{ERRORS};
	$cmds{STDERR}	||= $cmds{ERRORS};
	delete $cmds{ERRORS};
    }

    # Set up the override hook for warn() if requested.
    $SIG{__WARN__} = \&cpwarn if exists $cmds{WARN};

    # Set up the mailing lists for each channel as requested.
    $MailTo{WARN}   = [split /,/, $cmds{WARN}]   if $cmds{WARN};
    $MailTo{DIE}    = [split /,/, $cmds{DIE}]    if $cmds{DIE};
    $MailTo{STDOUT} = [split /,/, $cmds{STDOUT}] if $cmds{STDOUT};
    $MailTo{STDERR} = [split /,/, $cmds{STDERR}] if $cmds{STDERR};

    # Last, handle generic stdout and stderr unless the caller asks us not to.
    if ($ENV{ATRIA_FORCE_GUI} &&
			    (exists $cmds{STDOUT} || exists $cmds{STDERR})) {
	my $tmpout = tempname('stdout');
	my $tmperr = tempname('stderr');

	# Connect stdout and stderr to temp files for later use in END {}.
	if (exists $cmds{STDOUT}) {
	    open(HOLDOUT, '>&STDOUT');
	    open(STDOUT, ">$tmpout") || warn "$tmpout: $!";
	}
	if (exists $cmds{STDERR}) {
	    open(HOLDERR, '>&STDERR');
	    open(STDERR, ">$tmperr") || warn "$tmperr: $!";
	}

	# After program finishes, collect any stdout/stderr and display
	# with clearprompt and/or mail it out.
	END {
	    # retain original exit code on stack
	    my $rc = $?;
	    local $?;

	    # Restore stdout and stderr to their original fd's.
	    if (defined fileno HOLDOUT) {
		open(STDOUT, '>&HOLDOUT');
		close(HOLDOUT);
	    }
	    if (defined fileno HOLDERR) {
		open(STDERR, '>&HOLDERR');
		close(HOLDERR);
	    }

	    # Then display any stdout we captured in a dialog box.
	    if (defined($tmpout) && -e $tmpout) {
		open(OUT, $tmpout) || warn "$prog: $tmpout: $!";
		my @msg = <OUT>;
		close(OUT);
		if (@msg) {
		    my $title = "STDOUT\n\n @msg";
		    _automail('STDOUT', $MailTo{STDOUT},
				"Stdout from $prog", @msg) if $MailTo{STDOUT};
		    clearprompt(qw(proceed -type o -mask p -pref -pro), $title);
		}
		if (!$ENV{CLEARCASE_CLEARPROMPT_KEEP_CAPTURE}) {
		    # On Windows, we can't unlink this tempfile while
		    # any asynchronous dialog boxes are still on the
		    # screen due to threading/locking design, so we
		    # give the user some time to read & close them.
		    if (MSWIN()) {
			system(1, qq($^X -e "sleep 30; unlink '$tmpout'"));
		    } else {
			unlink($tmpout) || print "$prog: $tmpout: $!\n";
		    }
		}
	    }
	    # Same as above but for stderr.
	    if (defined($tmperr) && -e $tmperr) {
		my @msg;
		{
		    open(ERR, $tmperr) || warn "$prog: $tmperr: $!";
		    local $^W = 0; # <ERR> gives bogus error with AS build 623
		    @msg = <ERR>;
		    close(ERR);
		}
		if (@msg) {
		    my $title = "STDERR\n\n @msg";
		    _automail('STDERR', $MailTo{STDERR},
				"Stderr from $prog", @msg) if $MailTo{STDERR};
		    clearprompt(qw(proceed -type o -mask p -pref -pro), $title);
		}
		if (!$ENV{CLEARCASE_CLEARPROMPT_KEEP_CAPTURE}) {
		    if (MSWIN()) {
			system(1, qq($^X -e "sleep 30; unlink '$tmperr'"));
		    } else {
			unlink($tmperr) || print "$prog: $tmperr: $!\n";
		    }
		}
	    }
	}
    }
}

# This is a pseudo warn() which is called via the $SIG{__WARN__} hook.
sub cpwarn {
    my @msg = @_;
    # always show line numbers if this dbg flag set
    if ($ENV{CLEARCASE_CLEARPROMPT_SHOW_LINENO}) {
	my($file, $line) = (caller)[1,2];
	chomp $msg[-1];
	push(@msg, " at $file line $line.\n");
    }
    _automail('WARN', $MailTo{WARN}, "Warning from $prog", @msg)
							    if $MailTo{WARN};
    if ($ENV{ATRIA_FORCE_GUI}) {
	clearprompt(qw(proceed -type w -mask p -pref -pro), "WARNING\n\n@msg");
	return undef; 	# to keep clearprompt() in void context
    } else {
	warn @msg;
    }
}

# A pseudo die() which can be made to override the caller's builtin.
sub die {
    my @msg = @_;
    # always show line numbers if this dbg flag set
    if ($ENV{CLEARCASE_CLEARPROMPT_SHOW_LINENO}) {
	my($file, $line) = (caller)[1,2];
	chomp $msg[-1];
	push(@msg, " at $file line $line.\n");
    }
    _automail('DIE', $MailTo{DIE}, "Error from $prog", @msg)
							    if $MailTo{DIE};
    if ($ENV{ATRIA_FORCE_GUI}) {
	clearprompt(qw(proceed -type e -mask p -pref -pro), "ERROR\n\n@msg");
	exit $! || $?>>8 || 255;	# suppress the msg to stderr
    } else {
	require Carp;
	CORE::die Carp::shortmess(@_);

    }
}

1;

__END__

=head1 NAME

ClearCase::Common::ClearPrompt - Handle clearprompt in a portable, convenient way

=head1 SYNOPSIS

 use ClearCase::Common::ClearPrompt qw(clearprompt);

 # Boolean usage
 my $rc = clearprompt(qw(yes_no -mask y,n -type ok -prompt), 'Well?');

 # Returns text into specified variable (context sensitive).
 my $txt = clearprompt(qw(text -pref -pro), 'Enter text data here: ');

 # Asynchronous usage - show dialog box and continue
 clearprompt(qw(proceed -mask p -type ok -prompt), "You said: $txt");

 # Trigger series (record/replay responses for multiple elements)
 use ClearCase::Common::ClearPrompt qw(clearprompt +TRIGGERSERIES);
 my $txt = clearprompt(qw(text -pref -pro), 'Response for all elems: ');

 # Automatically divert trigger error msgs to clearprompt dialogs
 use ClearCase::Common::ClearPrompt qw(+ERRORS);

 # Prompt for a directory (not supported natively by clearprompt cmd)
 use ClearCase::Common::ClearPrompt qw(clearprompt_dir);
 my $dir = clearprompt_dir('/tmp', "Please choose a directory");

=head1 DESCRIPTION

This module provides four areas of functionality, each based on
clearprompt in some way but otherwise orthogonal. These are:

=over 4

=item * Clearprompt Abstraction

Provides a simplified interface to the B<clearprompt> program, taking
care of creating and removing temp files as required.

=item * Trigger Series Support

Records and replays responses across multiple trigger firings.

=item * Message Capture

Catches messages to stdout or stderr which would otherwise be lost in a
GUI environment and pops them up as dialog boxes using clearprompt.

=item * Directory Chooser

Allows clearprompt to be used to select directories (aka folders).

=back

All of which are discussed in more detail below.

=head2 CLEARPROMPT ABSTRACTION

Native ClearCase provides a utility (B<clearprompt>) for collecting
user input or displaying messages within triggers. However, use of
this tool is awkward and error prone, especially in multi-platform
environments.  Often you must create temp files, invoke clearprompt to
write into them, open them and read the data, then unlink them. In many
cases this code must run seamlessly on both Unix and Windows systems
and is replicated throughout many scripts. ClearCase::Common::ClearPrompt
abstracts this dirty work without changing the interface to
B<clearprompt>.

The C<clearprompt()> function takes the exact same set of flags as
the eponymous ClearCase command, e.g.:

    my $response = clearprompt('text', '-def', '0', '-pro', 'Well? ');

except that the C<-outfile> flag is unnecessary since creation,
reading, and removal of this temp file is managed internally.

In a void context, clearprompt() behaves asynchronously; i.e. it
displays the dialog box and returns so that execution can continue.
This allows it to be used for informational displays. In any other
context it waits for the dialog's button to be pushed and returns the
appropriate data type.

The clearprompt() I<function> always leaves the return code of the
clearprompt I<command> in C<$?> just as C<system('clearprompt ...')>
would.  If the prompt was interrupted via a signal, the function
returns the undefined value.

=head2 TRIGGER SERIES

Since clearprompt is often used in triggers, special support is
provided in ClearCase::Common::ClearPrompt for multiple trigger firings
deriving from a single CC operation upon multiple obects.

If the boolean $ClearCase::Common::ClearPrompt::TriggerSeries has a true value,
clearprompt will 'stash' its responses through multiple trigger
firings. For instance, assuming a checkin trigger which prompts the
user for a bugfix number and a command "cleartool ci *.c", the
TriggerSeries flag would cause all response(s) to clearprompts for the
first file to be recorded and replayed for the 2nd through nth trigger
firings. The user gets prompted only once.

Trigger series behavior can also be requested at import time via:

    use ClearCase::Common::ClearPrompt qw(+TRIGGERSERIES);

This feature is only available on CC versions which support the
CLEARCASE_SERIES_ID environment variable (3.2.1 and up) but attempts to
use it are harmless in older versions. The module will just drop back
to prompting per-file in that case.

=head2 MESSAGE CAPTURE

In a ClearCase GUI environment, output to stdout or stderr (typically
from a trigger) has no console to go to and thus disappears without a
trace. This applies to both Unix and Windows GUI's and - especially on
Windows where the GUI is used almost exclusively - can cause trigger
bugs to go undetected for long periods. Trigger scripts sometimes exec
I<clearprompt> manually to display error messages but this is laborious
and will not catch unanticipated errors such as those emanating from
included modules or child processes.

ClearCase::Common::ClearPrompt can be told to fix this problem by capturing all
stderr/stdout and displaying it automatically using I<clearprompt>.
There's also a facility for forwarding error messages to a specified
list of users via email.

ClearPrompt can capture messages to 4 "channels": the stdout and stderr
I/O streams and the Perl warn() and die() functions. As the latter two
send their output to stderr they could be subsumed by the stderr
channel, but they have slightly different semantics and are thus
treated separately; messages thrown by warn/die are I<anticipated>
errors from within the current (perl) process. Other messages arriving
on stderr will typically be I<unexpected> messages not under the
control of the running script, for instance those from a backquoted
cleartool command. This distinction is especially important in triggers
where the former may represent a policy decision and the latter a plain
old programming bug or system error. Warn/die captures are also
displayed with the appropriate GUI icons and the title "Warning" or
"Error".

The 4 channels are known as WARN, DIE, STDOUT, and STDERR. To capture
any of them to clearprompt just specify them with a leading C<+> at
I<use> time:

	use ClearCase::Common::ClearPrompt qw(+STDERR +WARN +DIE);

These 3 "error channels" can also be requested via the meta-command

	use ClearCase::Common::ClearPrompt qw(+ERRORS);

while all 4 can be captured with

	use ClearCase::Common::ClearPrompt qw(+CAPTURE);

Messages may be automatically mailed to a list of users by attaching
the comma-separated list to the name of the channel using '=' in the
import method, e.g.

    use ClearCase::Common::ClearPrompt '+ERRORS=vobadm';
    use ClearCase::Common::ClearPrompt qw(+STDOUT=vobadm +STDERR=tom,dick,harry);

Note: the email feature requires the Net::SMTP module to be installed
and correctly configured. You may find the supplied
C<./examples/smtp.pl> script useful for this purpose.

=head2 SAMPLE CAPTURE USAGE

Try setting ATRIA_FORCE_GUI=1 by hand and running the following little
script which generates a warning via C<warn()> and a hard error from a
child process:

   BEGIN { $ENV{ATRIA_FORCE_GUI} = 1 }
   use ClearCase::Common::ClearPrompt qw(+CAPTURE);
   warn qq(This is a warning\n);
   system q(perl nosuchscript);

You should see a couple of error msgs in dialog boxes, and none on
stderr.  Removing the C<+CAPTURE> would leave the messages on text-mode
stderr.  Changing it to C<+WARN> would put the I<warning> in a dialog
box but let the I<error msg> come to text stderr, while C<+STDERR>
would put both messages in the same dialog since C<warn()> would no
longer be treated specially. Appending "=E<lt>usernameE<gt>" would
cause mail to be sent to E<lt>usernameE<gt>.

=head2 DIRECTORY PROMPTING

The clearprompt command has no builtin directory chooser, so this
module provides a separate C<clearprompt_dir()> function which
implements it with "clearprompt list" and C<opendir/readdir/closedir>.
Usage is

    use ClearCase::Common::ClearPrompt qw(clearprompt_dir);
    $dir = clearprompt_dir($starting_dir, $prompt_string);

This is pretty awkward to use since it doesn't employ a standard
directory-chooser interface but it works.  The only way to make your
selection final is to select "." or hit the Abort button.  And there's
no way to I<create> a directory via this interface. You would not use
this feature unless you had to, typically.

=head1 MORE EXAMPLES

Examples of advanced usage can be found in the test.pl script. There
is also a <./examples> subdir with a few sample scripts.

=head1 ENVIRONMENT VARIABLES

An interactive shell will be automatically invoked if the
B<CLEARCASE_CLEARPROMPT_DEBUG_SHELL> EV is set. If its value is the
name of an executable program that program will be run; otherwise the
system shell (C</bin/sh> or C<cmd.exe>) is used. This is quite valuable
for developing and debugging trigger scripts because it lets the
developer explore the runtime environment of the script (the
C<CLEARCASE_*> env vars, the current working directory, etc.). E.g.

	export CLEARCASE_CLEARPROMPT_DEBUG_SHELL=/bin/ksh

will cause an interactive Korn shell to be started before the script
executes. The script continues iff the shell returns a zero exit
status.

There are a few other EV's used to control or override this module's
behaviors but they are documented only in the code. They all match the
pattern C<CLEARCASE_CLEARPROMPT_*>.

=head1 NOTES

I<An apparent undocumented "feature" of clearprompt(1) is that it
catches SIGINT (Ctrl-C) and provides a status of 4 rather than
returning the signal number in C<$?> according to normal (UNIX) signal
semantics.>  We fix that up here so it looks like a normal signal 2.
Thus, if C<clearprompt()> returns undef the signal number is reliably
in $? as it's documented to be.

Also, there is a bug in ClearCase 4.0 for Win32. The list option
doesn't display the prompt text correctly. This is a bug in CC itself,
not the module, and is fixed in CC 4.1.

=head1 PORTING

This package is known to work fine on Solaris 2.5.1/perl5.004_04,
Solaris 7/perl5.6, and Windows NT 4.0SP3/5.005_02.  As these platforms
are quite different they should take care of any I<significant>
portability issues but please send reports of tweaks needed for other
platforms to the address below.

=head1 AUTHOR

David Boyce <dsb@boyski.com>

Copyright (c) 1999-2001 David Boyce. All rights reserved.  This Perl
program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

clearprompt(1), perl(1)

=cut
