# sh-tests

This is a shell-based test framework.
It's mostly useful for projects written in a language without native unit test support (like other shell scripts)
or for tiny projects for which an entire unit test framework would be overkill.


# Writing a simple test

This is what a minimal test script could look like:

```sh
#!/bin/sh

# Load init.sh, assuming it's in the same dir as the test script.
# This provides us with all assertion functions and some additional helper functions and variables.
. $(dirname "$0")/init.sh

# Try to compile our project files. init.sh has set $HERE to the test script's dir.
# assertCmd() by default expects a return status of zero,
# i.e. it expects the make command to succeed.
assertCmd "make -C $HERE/../"

# Last line: cleanup and show a green success line for this test script!
success
```

Calling this script will look something like this,
if everything works:

```
$ ./00-test-compile.sh
Starting 00-test-compile...
Success: 00-test-compile
```


# Package structure

Test scripts only need to source the *[init.sh](init.sh)* file to be operational.
The *[assert.sh](assert.sh)* file will be sourced automatically.

The *init.sh* and *assert.sh* framework scripts need to be located
in the same directory as the test script(s),
but symlinks to them work fine.

(*init.sh* must be sourced from the test script to be able to define new variables and functions.
In some shells, e.g. *dash*, sourced scripts have no way of knowing their own path,
so they cannot call other files in the same directory --
unless of course they can rely on their caller living in the same directory,
in which case they can get that directory from `$0`.)

The *[run-all-tests.sh](run-all-tests.sh)* script executes all files in the script's directory
that match the filename pattern
`??-test-*.sh`.
The files are run in whichever order the shell glob expansion returns,
which should be lexicographic order.  
It aborts immediately if one of the test script fails.
If all test scripts were run successfully,
it prints a green
"All tests executed successfully"
line and ends.


# Assertion functions

All assertion functions produce no output by themselves if they succeed.
If they fail, they will print an error message detailing the failure
(unless overridden with the *errorMessage* argument accepted by some assertion functions),
and abort the test script,
exiting with a return status of 99.

* `assertCmd [-v] command [expectedReturnStatus=0]`  
	Tries to run a command and checks its return status.
	The command's *stdout* output will be saved in *$ASSERTCMDOUTPUT*,
	and won't be visible (unless the *-v* option is present).
	The command's *stderr* output will NOT be redirected.
	*expectedReturnStatus* can be any number (0..255),
	or the special value '*any*', in which case
	all return status values will be accepted
	(except 126 and 127, those are still considered a failure,
	because they usually signify a [shell command invocation error](http://www.tldp.org/LDP/abs/html/exitcodes.html)).

* `assertEq valueActual valueExpected [errorMessage]`  
	This assertion compares two strings and tests them for equality.

* `assertContains valueActual valueExpectedPart [errorMessage]`  
	This assertion compares two strings,
	expecting the second to be contained somewhere in the first.

* `assertRegex valueActual regex [errorMessage]`  
	This assertion checks whether the *regex* (PCRE regular expression)
	matches the *valueActual* string.
	The regex argument must be enclosed by slashes,
	can start with a '`!`' to negate the matching sense,
	and can end with `i`/`m`/`s` modifier(s).

* `assertEmpty valueActual [errorMessage]`  
	This assertion tests a string, expecting it to be empty.

* `assertCmdEq command expectedOutput [errorMessage]`  
	This assertion is a combination of *assertCmd*+*assertEq*.
	It executes a command, then compares its entire *stdout* output against *expectedOutput*.
	The command is expected to always have a return status of zero.

* `assertCmdEmpty command [errorMessage]`  
	This assertion is a combination of *assertCmd*+*assertEmpty*.
	It executes a command, then compares its entire *stdout* output against the empty string.
	The command is expected to always have a return status of zero.

* `assertFileSize fileName expectedSize [errorMessage]`  
	This assertion checks than a file exists and compares its total size (in bytes) against *expectedSize*.

* `assertFileMode fileName expectedOctalMode [errorMessage]`  
	This assertion checks that a file exists and compares its octal access mode
	(as printed by '*stat -c %a*', e.g. '*755*')
	against *expectedOctalMode*.

* `assertSubshellWasExecuted [errorMessage]`  
	This assertion checks whether the last subshell script created via *prepare_subshell()* has been executed.
	It does so by checking the existence of the marker file which the subshell script should have created.


# Project configuration

If your project needs some extra configuration for all or most of its tests,
create a file called *config.sh* in the same directory as the test scripts.
*init.sh* will automatically source that file if it exists.

This is the place to define additional helper variables and functions used across multiple tests,
override hook functions,
and to build custom assertion functions.
If most of your tests run the same binary,
it might be handy to define a variable with the binary's path in the *config.sh* file.


# Helper variables

*init.sh* also provides these environment variables:

* **$THIS**, the full path of the currently-running test script.  
	Example: `/home/mle/project-x/test/00-test-compile.sh`

* **$TESTNAME**, the current test script name (without its *.sh* suffix).  
	Example: `00-test-compile`

* **$HERE**, the directory where the current test script is located.  
	Example: `/home/mle/project-x/test`

* **$ASSERTSH**, the full path of the *assert.sh* script file, which has already been sourced by *init.sh*.


# Helper functions

*init.sh* also provides these helper functions:

* `success`  
	This function prints a green "*Success: $TESTNAME*" line,
	performs some cleanup,
	and ends the test script with exit status zero.
	Call it at the end of every test script!

* `fail errorMessage`  
	This function prints an error message in red on *stderr*,
	performs some cleanup,
	and ends the test script with exit status 99.
	This can be used for one-line mini-assertions:  
	`[ -x binfile ] || fail "binfile not found or not executable!"`

* `err errorMessage`  
	This function prints an error message in red on *stderr*
	(like *fail()*),
	but does NOT abort the test script.
	Use it if you want to print multi-line error messages before calling *fail()*.

* `skip [errorMessage]`  
	This function prints an error message in yellow on *stderr*
	and stops the test script,
	but with exit status zero (success).
	Use this, for example, if a precondition of your test script was not met
	and you don't consider that an actual test failure.

* `cd_tmpdir`  
	Creates a temporary directory to work in and changes into it.
	(Also changes *$ERRCOND* to point into the new directory, so we don't clutter the test root with them.)
	Use this if your test script wants to create some files/directories.
	The temporary directory will be automatically removed when the test script ends,
	provided it is empty.

* `prepare_subshell`  
	Prepares a subshell script and points the *$TMPSH* and *$SHELL* env vars to it.
	The subshell will always have *$IN_SUBSHELL=yes* set
	and will always source the assert.sh and config.sh files (if present).
	It can use all assertion functions, including *fail()*,
	but should not need to use *success()* or *cleanup()*.
	Pipe the subshell script contents to this function.  
	See "[Using subshells](#using-subshells)".

* `add_cleanup filename...`  
	Adds one or more filenames to the *$CLEANUP_FILES* list.
	Use this if your test script creates files in the temporary directory
	which should be automatically deleted as soon as the test script ends.
	Be careful, they'll be deleted with "rm -fd" and must not contain spaces.


# Hook functions

All available hook functions are empty stub functions defined in *init.sh*.
Override them in your test script or in your *config.sh* as necessary.

* **hook_cleanup()**, called on cleanup, i.e. when the test script ends (either because of a failed assertion or because it called *success()*). Use this instead of *add_cleanup()* if your test script needs to do some serious cleanup, especially if it might need to remove files with spaces in their names (which would not be safe for *add_cleanup()*, as its *$CLEANUP_FILES* list is space-delimited).


# Using subshells

To test a command which runs another command,
the usual approach is to have a helper script and supply that as the subcommand.
If the subcommand script should be able to perform its own *assert.sh* assertions,
it'll have to include that file by itself (the path is available in the *$ASSERTSH* env var).

The test framework offers the *prepare_subshell()* function to aid this process:
The function will create a new, randomly-named script file,
fill it with some initialization calls,
and append its *stdin* input.

Initialization done by all subshell scripts created by *prepare_subshell()*:

1. Sets env var *$IN_SUBSHELL=yes*,
1. creates a randomized marker file so that *assertSubshellWasExecuted()* will succeed,
1. includes the *assert.sh* script so that all assertion functions are available, as well as *fail()* and *err()*,
1. redefines *cleanup()* and *success()*, as they should not do anything inside a subshell,
1. includes the *config.sh* script (if it exists).

The filname of the new script file is stored in the *$TMPSH* and *$SHELL* env vars.
This can be useful to test commands which don't take a subcommand argument but simply start a new interactive shell.

*prepare_subshell()* requires a prior *cd_tmpdir()* call,
because it'll refuse to create the subshell script in the test root.


## Subshell example

This test script tests whether *bash* is installed,
whether bash supports the *-c* option to run arbitrary commands,
and whether bash correctly increments the *$SHLVL* counter by 1.

```sh
#!/bin/sh
. $(dirname "$0")/init.sh

export SHLVL=1

cd_tmpdir
prepare_subshell <<EOT
  assertEq "\$SHLVL" 2  "bash executed the subshell script, but did not correctly increment the SHLVL counter!"
EOT

# The subshell script's filename is now stored in $TMPSH.
# Try to run 'bash -c subshell', verify that it terminates with exit status zero.
assertCmd "bash -c $TMPSH"

# If 'bash -c' did not actually work correctly but still exited with a zero status,
# then assertCmd() did not notice anything amiss.
# Verify that the subshell script has been executed at least once:
assertSubshellWasExecuted

success
```


# Author

Maximilian Eul
\<[maximilian@eul.cc](mailto:maximilian@eul.cc)\>

https://github.com/mle86/sh-tests

