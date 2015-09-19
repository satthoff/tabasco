#
#
# This software is copyright (c) 2014 by Dipl. Inform. Uwe Satthoff.
#
# This is free software; you can redistribute it and/or modify it under the same terms
# as the Perl 5 programming language system itself.
#
# Contact: jcp@comasy.de
#
# Hamburg, 08-11/2014 - Uwe Satthoff
#-------------------------------------------------------------------------------------

#-------------------------------------------------------------------------------------
# BEGIN: activities and releases
#
# Activities to be used as branches have to be declared in the repository as a file named:
#   conf/task_activity/<activity name>.txt
#
# Releases to be used as tags have to be declared in the repository as a file named:
#   conf/task_release/<release name>.txt
# OR
#   the release name must be "<activity name>_<any string without white space>"
#
sub validActivity {
    my $svnlook  = shift; # object of class SVN::Look
    my $activity = shift; # activity name which in fact is a branch name

    eval {
	my $dummy = $svnlook->cat( 'conf/task_activity/' . $activity . '.txt' );
    };
    return 0 if( $@ );
    return 1;
}

sub validRelease {
    my $svnlook  = shift; # object of class SVN::Look
    my $activity = shift; # activity name which in fact is a branch name
    my $release  = shift; # release name which in fact is a tag name

    eval {
	my $dummy = $svnlook->cat( 'conf/task_release/' . $release . '.txt' );
    };
    if( $@ ) {
      # return 1: if not declared we allow anyway if it is the activity name tailored by '_<some string>'
      return 1 if( $release =~ m/^${activity}_\S+$/ );
      return 0;
    }
    return 1;
}
#
# END: activities and releases
#-------------------------------------------------------------------------------------


GENERIC(
	'pre-commit'  => \&tabasco_pre_commit
       );

use File::Basename;

sub tabasco_pre_commit
  {
    my $svnlook = shift; # object of class SVN::Look

    my @changed    = $svnlook->changed();
    my @added      = $svnlook->added();
    my @updated    = $svnlook->updated();
    my @deleted    = $svnlook->deleted();
    my @properties = $svnlook->prop_modified();
    my @copyTo     = $svnlook->copied_to();
    my @copyFrom   = $svnlook->copied_from();

    my @errorMessage = ();

    if( grep m/\s+/, @changed ) {
      push @errorMessage, "white spaces are not permitted in names of version controlled files and directories.";
    } elsif( grep m/^conf\//, @changed ) {
      # any changes in the conf folder have to be committed in their own single commit
      my @tmp = grep m/^conf\//, @changed;
      if( $#tmp != $#changed ) {
	push @errorMessage, "Changes in the conf/ folder have to be committed without any other changes within a single commit.";
      }
    } elsif( grep m/\/tags\/$|\/branches\/$/, @added ) {
      # check for correct task creation
      my @tmp = sort( grep m/\/tags\/$|\/branches\/$/, @added );
      if( $#tmp != 1 ) {
	push @errorMessage, "ERROR 1:";
	push @errorMessage, "To create a new task you must create the tags and branches folders in the same parent directory, which is the name of the new task.";
	push @errorMessage, "You cannot commit any other changes beside the creation of the two folders tags and branches of ONE new task except the creation/change of the root path.";
      } else {
	my @tagsFolder = grep m/\/tags\/$/, @tmp;
	my @branchesFolder = grep m/\/branches\/$/, @tmp;
	my $tagParent = File::Basename::dirname( $tagsFolder[0] );
	my $branchParent = File::Basename::dirname( $branchesFolder[0] );
	if( "$tagParent" ne "$branchParent" ) {
	  push @errorMessage, "ERROR 2:";
	  push @errorMessage, "To create a new task you must create the tags and branches folders in the same parent directory, which is the name of the new task.";
	  push @errorMessage, "You cannot commit any other changes beside the creation of the two folders tags and branches except the creation/change of the root path.";
	} else {
	  my $newTaskName = $tagParent;
	  if( $tagParent =~ m/trunk\/|tags\/|branches\// ) {
	    push @errorMessage, "ERROR 3:";
	    push @errorMessage, "To create a new task you must create the tags and branches folders in the same parent directory, which is the name of the new task.";
	    push @errorMessage, "The task name must not contain any directory named trunk, tags or branches,";
	    push @errorMessage, "and you cannot create folders named \"tags\" or \"branches\" under an existing branch or trunk.";
	    push @errorMessage, "Task name: >$newTaskName<";
	  } else {
	    my $pattern = quotemeta( $tagParent );
	    my @otherChanges = ();
	    push @otherChanges, @added;
	    push @otherChanges, @changed;
	    @otherChanges = grep !m/^$pattern\/branches\/$|^$pattern\/tags\/$/, @otherChanges;
	    if( grep !m/\/$/, @otherChanges ) {
	      # files were changed or added
	      push @errorMessage, "ERROR 4:";
	      push @errorMessage, "To create a new task you must create the tags and branches folders in the same parent directory, which is the name of the new task.";
	      push @errorMessage, "All other changes must only be changes/creations of directories within the parent directories.";
	      push @errorMessage, "Task name: >$newTaskName<";
	      my @invalidChanges = grep !m/\/$/, @otherChanges;
	      grep s/$/\n/, @invalidChanges;
	      $invalidChanges[0] = ' ' . $invalidChanges[0];
	      push @errorMessage, "Invalid changes:\n@invalidChanges";
	    } else {
	      my $taskName = $tagParent . '/';
	      foreach my $p ( sort @otherChanges ) {
		# all other changes must be within the parent directory = task name
		if( index( $taskName, $p ) == -1 ) {
		  push @errorMessage, "ERROR 5:";
		  push @errorMessage, "To create a new task you must create the tags and branches folders in the same parent directory, which is the name of the new task.";
		  push @errorMessage, "All other changes must only be changes/creations of directories within the parent directories.";
		  push @errorMessage, "Task name: >$newTaskName<";
		  push @errorMessage, "Invalid change: >$p<";
		  last;
		}
	      }
	    }
	  }
	}
      }
    } elsif( grep m/\/trunk\/$|^branches\/[^\/\s]+\/$|\/branches\/[^\/\s]+\/$|^tags\/[^\/\s]+\/$|\/tags\/[^\/\s]+\/$/, @added )  {
      # creation of a trunk, a tag or a branch
      my @tmp = grep m/\/trunk\/$|^branches\/[^\/\s]+\/$|\/branches\/[^\/\s]+\/$|^tags\/[^\/\s]+\/$|\/tags\/[^\/\s]+\/$/, @added;
      if( $#tmp != 0 or
	  $#changed != 0 or
	  $#copyTo != 0 or
	  $#copyFrom != 0 or
	  $tmp[0] ne $copyTo[0] ) {
	push @errorMessage, "ERROR 6:";
	push @errorMessage, "To create a trunk, a branch or a tag the operation must be performed with a svn-copy operation as a single operation without any other changes.";
      } else {
	my $source = $copyFrom[0];
	my $target = $copyTo[0];
	if( $tmp[0] =~ m/trunk\/$/ ) {
	  # trunk creation
	  if( $source !~ m/tags\/[^\/\s]+\/$/ ) {
	    push @errorMessage, "ERROR 7:";
	    push @errorMessage, "A new trunk can only be created with a svn-copy operation from a tag of the same task.";
	    push @errorMessage, "Invalid source: >$source<";
	  } else {
	    $source =~ s/^(.*)tags\/[^\/\s]+\$/$1/;
	    $source =~ s/\/$//;
	    $target =~ s/^(.*)trunk\/$/$1/;
	    $target =~ s/\/$//;
	    if( "$source" ne "$target" ) {
	      push @errorMessage, "ERROR 8:";
	      push @errorMessage, "A new trunk can only be created with a svn-copy operation from a tag of the same task.";
	      push @errorMessage, "Source: >$source<";
	      push @errorMessage, "Target: >$target<";
	    }
	  }
	} elsif( $tmp[0] =~ m/branches\/[^\/\s]+\/$/ ) {
	  # branch creation
	  if( $source !~ m/tags\/[^\/\s]+\/$/ ) {
	    push @errorMessage, "ERROR 9:";
	    push @errorMessage, "A new branch can only be created with a svn-copy operation from a tag of the same task.";
	    push @errorMessage, "Invalid source: >$source<";
	  } else {
	    $source =~ s/^(.*)tags\/[^\/\s]+\/$/$1/;
	    $source =~ s/\/$//;
	    my $branchName = $target;
	    $branchName =~ s/^.*branches\/([^\/\s]+)\/$/$1/;
	    $target =~ s/^(.*)branches\/[^\/\s]+\/$/$1/;
	    $target =~ s/\/$//;
	    if( "$source" ne "$target" ) {
	      push @errorMessage, "ERROR 10:";
	      push @errorMessage, "A new branch can only be created with a svn-copy operation from a tag of the same task.";
	      push @errorMessage, "Source: >$source<";
	      push @errorMessage, "Target: >$target<";
	    } elsif( not validActivity( $svnlook, $branchName ) ) {
	      push @errorMessage, "DECLARATION ERROR:";
	      push @errorMessage, "The new branch >$branchName< is not specified as a valid task activity.";
	    }
	  }
	} else {
	  # tag creation
	  if( $target =~ m/tags\/BASELINE\/$/ ) {
	    # creation of task baseline
	    if( $source !~ m/tags\/[^\/\s]+\/$/ ) {
	      push @errorMessage, "ERROR 11:";
	      push @errorMessage, "The baseline of a task (tag = BASELINE) can only be created with a svn-copy operation from a tag of a parent task.";
	      push @errorMessage, "Invalid source: >$source<";
	    } else {
	      $source =~ s/^(.*)tags\/[^\/\s]+\/$/$1/;
	      $target =~ s/^(.*)tags\/[^\/\s]+\/$/$1/;
	      if( "$source" eq "$target" ) {
		push @errorMessage, "ERROR 12:";
		push @errorMessage, "The baseline of a task (tag = BASELINE) can only be created with a svn-copy operation from a tag of a parent task.";
		push @errorMessage, "Source: >$source<";
		push @errorMessage, "Target: >$target<";
	      } else {
		while( 1 == 1 ) {
		  last if( $source eq '.' );
		  if( index( $target, $source ) == -1 ) {
		    push @errorMessage, "ERROR 13:";
		    push @errorMessage, "The baseline of a task (tag = BASELINE) can only be created with a svn-copy operation from a tag of a parent task.";
		    push @errorMessage, "Source: >$source<";
		    push @errorMessage, "Target: >$target<";
		    last;
		  }
		  $source = File::Basename::dirname( $source );
		}
	      }
	    }
	  } else {
	    if( $source !~ m/branches\/[^\/\s]+\/$|trunk\/$/ ) {
		push @errorMessage, "ERROR 14:";
		push @errorMessage, "A new tag can only be created with a svn-copy operation from a branch or trunk of the same task.";
		push @errorMessage, "The BASELINE tag of a task has to be created with a svn-copy operation from a tag of a parent task.";
		push @errorMessage, "Invalid source: >$source<";
	    } else {
		my $branchName = $source;
		if( $source =~ m/branches\// ) {
		  $branchName =~ s/^.*branches\/([^\/\s]+)\/$/$1/;
		  $source =~ s/^(.*)branches\/[^\/\s]+\/$/$1/;
		  $source =~ s/\/$//;
		} else {
		  $branchName = 'trunk';
		  $source =~ s/^(.*)trunk\/$/$1/;
		  $source =~ s/\/$//;
		}
		my $tagName = $target;
		$tagName =~ s/^.*tags\/([^\/\s]+)\/$/$1/;
		$target =~ s/^(.*)tags\/[^\/\s]+\/$/$1/;
		$target =~ s/\/$//;
		if( "$source" ne "$target" ) {
		  push @errorMessage, "ERROR 15:";
		  push @errorMessage, "A new tag can only be created with a svn-copy operation from a branch or trunk of the same task.";
		  push @errorMessage, "Source: >$source<";
		  push @errorMessage, "Target: >$target<";
		} elsif( not validRelease( $svnlook, $branchName, $tagName ) ) {
		  push @errorMessage, "DECLARATION ERROR:";
		  push @errorMessage, "The new tag >$tagName< is not specified as a valid task release of branch >$branchName<.";
		}
	    }
	  }
	}
      }
    } elsif( grep !m/^trunk\/|\/trunk\/|^branches\/[^\/\s]+\/|\/branches\/[^\/\s]+\//, @changed ) {
      push @errorMessage, "ERROR 16:";
      push @errorMessage, "Any changes, except a task creation, can only be performed under a trunk or a branch.";
      if( @copyTo or @copyFrom ) {
	push @errorMessage, "In particular, you cannot change an existing task hierarchy by moving or renaming subtrees.";
      }
    }
    if( @errorMessage ) {
      grep s/$/\n/, @errorMessage;
      $errorMessage[0] = ' ' . $errorMessage[0];
      print STDERR "@errorMessage\n";
      exit -1;
    }
  }
1; # end of tabasco.pl

__END__

=pod

=encoding UTF-8

=head1 NAME - TABASCO

tabasco.pl - Subversion pre-commit hook controlling a component structure of tasks

=head1 VERSION

version 1.0

=head1 INTRODUCTION

=over

=item B<Subversion>

Subversion doesn't provide specific concepts for parallel development C<branches/> and baselining C<tags/>. Instead it is recommended 
to use a folder structure to simulate branches and tags,

=over

=item B<repository_root/branches/branch name/>

=item B<repository_root/tags/tag name>/>

=item B<repository_root/trunk/>

=back

and the svn-copy operation to create branches and tags.

To understand all about this please refer to L<http://svnbook.red-bean.com/nightly/en/index.html>.

=item B<TaBasCo>

TaBasCo, B<Ta>sk B<bas>ed B<Co>nfiguration Management, is a concept providing users a technique to perform their work in 
separate, insulated but not isolated working configurations of their software. These working configurations are named tasks.

For a more detailed description of the TaBasCo concept refer to L<https://comasy.de/>.

=item B<SVN::Hooks framework>

The tabasco pre-commit hook implementation uses the Subversion hook framework SVN::Hooks by Gustavo L. de M. Chaves 
L<mailto:gnustavo@cpan.org>.  To understand all about this please refer to L<https://metacpan.org/pod/SVN::Hooks>.

=back

=head2 TaBasCo tasks with Subversion

=over

=item B<repository_root/path/of/components/to/task_name>

A path in the repository, where each folder in the path could be itself a task, called a B<parent task>.

=item B<repository_root/path/of/components/to/task_name/branches/>

The branches folder forseen to hold branches of the task.

=item B<repository_root/path/of/components/to/task_name/tags/>

The tags folder forseen to hold tags of the task.

=item B<repository_root/path/of/components/to/task_name/tags/BASELINE/>

The BASELINE of the task, to be created by a svn-copy operation from a tag of a parent task.

=item B<repository_root/path/of/components/to/task_name/trunk/>

The trunk folder of the task being the main branch of the task.

=item B<the initial default task to be created at repository creation time>

If this hook shall be applied to a repository then the repository must have been created with its initial structure of the so-called default-
task.
This default-task is the parent task of all other tasks created later. Structure of the default task:

=over

=item B<repository_root/branches/>

=item B<repository_root/tags/>

=item B<repository_root/tags/BASELINE/> and the BASELINE should be empty.

=item B<repository_root/trunk/>

=back

=back

The hook ensures that any changes, except the creation of a new task, can only be performed under the trunk of a task or a branch 
(branches/branch_name/) of a task.
Especially any changes of tags (tags/tag_name/), except the creation of tags (see below), will be rejected by the hook.

=head2 Subversion task how to's

=head3 How to create a new task

To create a new task the path to the new task has to be created with its subfolders C<branches/> and C<tags/> in one svn-commit 
operation without any other changes.

=over

=item B<Example:>

=item B<repository_root/databases/server/CMDB/branches/>

=item B<repository_root/databases/server/CMDB/tags/>

=back

=head3 How to create the BASELINE of a new task

The BASELINE of a task (tags/BASELINE) can only be created by a svn-copy operation copying from a tag of a parent task.

=head3 How to create the trunk or a branch of a task

The trunk or a branch of a task can only be created by a svn-copy operation copying from a tag of the same task.

=head3 How to create a tag of a task

A tag of a task can only be created by a svn-copy operation copying from the trunk or a branch of the same task.
After a tag creation any changes under the new tags folder will be rejected by the hook including the deletion of the tag itself.

=head1 USAGE

To activate the hook for a repository the file tabasco.pl has to be required by the svn-hooks.pl file, which has to be created according the 
usage description of the SVN::Hooks package:

Extract from the SVN::Hooks description including the needed require statement C<require "path/to/tabasco.pl">:

In the Subversion server, go to the C<hooks> directory under the
directory where the repository was created. You should see there the
nine hook templates. Create a script there using the SVN::Hooks module.

	$ cd /path/to/repo/hooks

	$ cat >svn-hooks.pl <<END_OF_SCRIPT
	#!/usr/bin/perl

	use SVN::Hooks;
        use SVN::Hooks::Generic;

        require "path/to/tabasco.pl";

	run_hook($0, @ARGV);

	END_OF_SCRIPT

	$ chmod +x svn-hooks.pl

=head1 AUTHOR

Uwe Satthoff -  L<mailto:jcp@comasy.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Diplom Informatiker Uwe Satthoff - L<https://comasy.de>

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

