
%COMMAND_SHORTCUT = (
    help     => 'helpText',
    crta     => 'createTask',
    crre     => 'createRelease',
    lsta     => 'listTasks',
    usta     => 'useTask',
    usre     => 'useRelease',
    mire     => 'mergeInRelease',
    rere     => 'recommendRelease'
    );

%COMMAND = (
    helpText     => {
	short => 'help',
	package     => 'CLI::Command::printHelpText',
	description => 'Print help text',
	helptext    => "

*** USAGE

    helpText (help) [command]

"
    },
        recommendRelease  => {
	short => 'rere',
	package     => 'CLI::Command::recommendRelease',
	description => 'not yet implemented',
	helptext    => "

*** USAGE

    recommendRelease - not yet implemented.

    Recommend release for usage with commands
    rebaseWithParentTask or mergeInRelease

"
    },
        mergeInRelease  => {
	short => 'mire',
	package     => 'CLI::Command::mergeInRelease',
	description => 'not yet implemented',
	helptext    => "

*** USAGE

    mergeInRelease -target <task name>
                   -latest <task name> |
                   -recommended <task name> |
                   -release <release name>

    Perform a cspec/view merge from the selected release into the target task,
    but only for those paths of the release's task which are
    visible and writable for the target task.

"
    },
    createTask  => {
	short => 'crta',
	package => 'CLI::Command::createTask',
	description => 'creates a new task',
	helptext    => "

*** USAGE

    createTask  -name <new task name>  [ -comment <free text> ]
                        { -baseline <release of another task>  [-restrictpaths]      |
                          -paths <filename of a file with absolute Vob paths, one per line> }


    This command creates a new task.

    With option -baseline, the baseline of the new task will be a release of another task.
    The other task becomes the parent task of the new task.
    If option -restrictpaths is specified a path selection dialog starts after successful task creation.
    Within this dialog the new task can be restricted to work only on subpaths of its parent task.
    Default is, that the new task inherits all paths of its parent task.

    With option -paths a new initial task will be created which does not have a parent task.
    The current view's config spec determines which versions of the specified paths forms together
    the baseline of the new task.
    The baseline of the new task will be created as a initial release and all selected Vob paths will
    be recursively fully labeled with the name of the newly created release.
    The baseline of the new task is named upper case of( <task name> _BASELINE).

"
    },
    createRelease  => {
	short => 'crre',
	package => 'CLI::Command::createRelease',
	description => 'creates a new release',
	helptext    => "

*** USAGE

    createRelease -task <task name>  [ -comment <free text> ] [ -full ]


    This command creates a new release in the specified task.
    The new release name is upper case of( <task name> . GMT . <actual GMT time> )

    With option -full the new release will become a full release.
    Default is a delta release.

"
    },
    listTasks  => {
	short => 'lsta',
	package => 'CLI::Command::listTasks',
	description => 'list existing tasks with their releases',
	helptext    => "

*** USAGE

    listTasks  [ -long ] [ <task name> <task name> ... ] | -struct


    This command displays existing tasks.
    With option -long the config specs of tasks and a list of their releases will be displayed as well.
    With option -struct the task tree structure of all root tasks will be displayed.

"
    },
    useTask  => {
	short => 'usta',
	package => 'CLI::Command::useTask',
	description => 'sets the config spec of a task in a view',
	helptext    => "

*** USAGE

    useTask  -task <task name>  -view <view tag>


    This command gets the config spec of the specified task
    and applies it to the specified view.

"
    },
    useRelease  => {
	short => 'usre',
	package => 'CLI::Command::useRelease',
	description => 'sets the config spec of a release in a view',
	helptext    => "

*** USAGE

    useRelease  -release <release name>  -view <view tag>


    This command gets the config spec of the specified release
    and applies it to the specified view.

"
    }
    );

  # comm -- like the UNIX utility
  #
  # Arg1 is a reference to array1
  # Arg2 is a referenct to array2
  #
  # Returns references to three arrays:
  #  Ret1 = the entries that are in array1 but not array2
  #  Ret2 = the entries that are in array2 but not array1
  #  Ret3 = the entries that are in both array1 and array2
  #
  sub comm {
    my ($a1, $a2) = @_;
    my (@r1, @r2, @r12) = ((),(),());

    @$a1 or @$a2 or goto DONE;

    my ($i1, $i2) = (0, 0);

    while (1) {

      # If we've used up the first array, then the only possible action left
      # is to return items in array2
      #
      if ($i1 > $#$a1) {
        push @r2, @{$a2}[$i2 .. $#$a2];
        last;
      }

      # If we've used up the second array, then the only possible action left
      # is to return items in array1
      #
      if ($i2 > $#$a2) {
        push @r1, @{$a1}[$i1 .. $#$a1];
        last;
      }

      my $c = $a1->[$i1] cmp $a2->[$i2];

      # If they're equal, handle that and increment both.
      #
      if (!$c) {
        push @r12, $a1->[$i1];
        ++$i1; ++$i2;
        next;
      }

      # If a1 > a2, increment a2 until it's >= a1.  Add that slice to @r2
      #
      if ($c == 1) {
        my $s = $i2;
        ++$i2 until (!defined($a2->[$i2]) or $a1->[$i1] le $a2->[$i2]);
        push @r2, @{$a2}[$s .. $i2-1];
        next;
      }

      # If a2 > a1, increment a1 until it's >= a2.  Add that slice to @r1
      #
      my $s = $i1;
      ++$i1 until (!defined($a1->[$i1]) or $a2->[$i2] le $a1->[$i1]);
      push @r1, @{$a1}[$s .. $i1-1];
    }

  DONE:
    return (\@r1, \@r2, \@r12);
  };
1;
