
%COMMAND_SHORTCUT = (
    help     => 'helpText',
    crta     => 'createTask',
    crre     => 'createRelease',
    lsta     => 'listTasks'
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
    createTask  => {
	short => 'crta',
	package => 'CLI::Command::createTask',
	description => 'creates a new task with baseline = release provided with option -baseline',
	helptext    => "

*** USAGE

    createTask  -name <new task name> -baseline <release of another task> [ -comment <free text line> ]


    This command creates a new task with the specified baseline.

"
    },
    createRelease  => {
	short => 'crre',
	package => 'CLI::Command::createRelease',
	description => 'creates a new release in the task specified with option -task',
	helptext    => "

*** USAGE

    createRelease -task <task name>  [ -comment <free text line> ]


    This command creates a new release in the specified task.
    The new release name is upper_count_of( <task name> . GMT . <actual GMT time> )

"
    },
    listTasks  => {
	short => 'lsta',
	package => 'CLI::Command::listTasks',
	description => 'list existing tasks with their releases',
	helptext    => "

*** USAGE

    listTasks  [ -long ] [ <task name> <task name> ... ]


    This command displays existing tasks with their releases.
    With option -long the config specs of tasks and releases will be displayed as well.

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
