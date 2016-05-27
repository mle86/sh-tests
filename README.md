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


# Assertion functions

All assertion functions produce no output by themselves if they succeed.
If they fail, they will print an error message detailing the failure
(unless overridden with the *errorMessage* argument accepted by some assertion functions),
and abort the test script,
exiting with a return status of 99.

* `assertCmd [-v] command [expectedReturnStatus=0]`
	\
	Tries to run a command and checks its return status.
	The command's *stdout* output will be saved in *$ASSERTCMDOUTPUT*,
	and won't be visible (unless the *-v* option is present).
	The command's *stderr* output will NOT be redirected.
	*expectedReturnStatus* can be any number (0..255),
	or the special value '*any*', in which case
	all return status values will be accepted
	(except 127 and 128, those are still considered a failure,
	because they usually signify a shell command invocation error).

* `assertEq valueActual valueExpected [errorMessage]`
	\
	This assertion compares two strings and tests them for equality.

* `assertEmpty valueActual [errorMessage]`
	\
	This assertion tests a string, expecting it to be empty.

* `assertCmdEq command expectedOutput [errorMessage]`
	\
	This assertion is a combination of *assertCmd*+*assertEq*.
	It executes a command, then compares its entire *stdout* output against *expectedOutput*.
	The command is expected to always have a return status of zero.

* `assertCmdEmpty command [errorMessage]`
	\
	This assertion is a combination of *assertCmd*+*assertEmpty*.
	It executes a command, then compares its entire *stdout* output against the empty string.
	The command is expected to always have a return status of zero.

* `assertFileSize fileName expectedSize [errorMessage]`
	\
	This assertion checks than a file exists and compares its total size (in bytes) against *expectedSize*.

* `assertFileMode fileName expectedOctalMode [errorMessage]`
	\
	This assertion checks that a file exists and compares its octal access mode
	(as printed by '*stat -c %a*', e.g. '*755*')
	against *expectedOctalMode*.


# Helper variables

*init.sh* also provides these environment variables:

* **$THIS**, the full path of the currently-running test script.
	\
	Example: `/home/mle/project-x/test/00-test-compile.sh`

* **$TESTNAME**, the current test script name (without its *.sh* suffix).
	\
	Example: `00-test-compile`

* **$HERE**, the directory where the current test script is located.
	\
	Example: `/home/mle/project-x/test`

* **$ASSERTSH**, the full path of the *assert.sh* script file, which has already been sourced by *init.sh*.

* **$CLEANUP_FILES**, additional files which the test script wants to be deleted after the test finished.
	Is empty by default.
	Separate with spaces. Be careful, they'll be deleted with "*rm -fd*".


# Helper functions

*init.sh* also provides these helper functions:

* `success`
	\
	This function prints a green "*Success: $TESTNAME*" line,
	performs some cleanup,
	and ends the test script with exit status zero.
	Call it at the end of every test script!

* `fail errorMessage`
	This function prints an error message in red on *stderr*,
	performs some cleanup,
	and ends the test script with exit status 99.
	This can be used for one-line mini-assertions:
	\
	`[ -x binfile ] || fail "binfile not found or not executable!"`

* `err errorMessage`
	\
	This function prints an error message in red on *stderr*
	(like *fail()*),
	but does NOT abort the test script.
	Use it if you want to print multi-line error messages before calling *fail()*.

* `cd_tempdir`
	\
	Creates a temporary directory to work in and changes into it.
	(Also changes *ERRCOND* to point into the new directory, so we don't clutter the test root with them.)
	Use this if your test script wants to create some files/directories.
	The temporary directory will be automatically removed when the test script ends,
	provided it is empty.

* `prepare_subshell`
	\
	**TODO**


# Hook functions

All available hook functions are empty stub functions defined in *init.sh*.
Override them in your test script or in your *config.sh* as necessary.

* **hook_cleanup()**, called on cleanup, i.e. when the test script ends (either because of a failed assertion or because it called *success()*). Use this instead of *$CLEANUP_FILES* if your test script needs to do some serious cleanup, especially if it might need to remove files with spaces in their names (which would not be safe for the space-delimited *$CLEANUP_FILES* list).


# Using subshells

**TODO**


# Author

Maximilian Eul
\<[maximilian@eul.cc](mailto:maximilian@eul.cc)\>

https://github.com/mle86/sh-tests

