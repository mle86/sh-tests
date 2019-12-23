# sh-tests

[![Build Status](https://travis-ci.org/mle86/sh-tests.svg?branch=master)](https://travis-ci.org/mle86/sh-tests)

This is a shell-based test framework.
It's mostly useful for projects written in a language without native unit test support (like other shell scripts)
or for tiny projects for which an entire unit test framework would be overkill.

[subshells]: doc/Subshell_Testing.md


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
so they cannot call other files in the same directory –
unless of course they can rely on their caller living in the same directory,
in which case they can get that directory from `$0`.)

The *[run-all-tests.sh](run-all-tests.sh)* script executes all files in the script's directory
that match the filename pattern
`??-test-*.sh`.
The files are run in lexicographic order.  
It aborts immediately if one of the test script fails.
If all test scripts were run successfully,
it prints a green
“All _N_ tests executed successfully”
line and ends.


# Assertion functions

All assertion functions produce no output by themselves if they succeed.
If they fail, they will print an error message detailing the failure
(unless overridden with the *errorMessage* argument accepted by some assertion functions),
and abort the test script,
exiting with a return status of 99.

* <code><b>assertCmd</b> [-v] command [expectedReturnStatus=0]</code>  
	Tries to run a command and checks its return status.
	The command's *stdout* output will be saved in *$ASSERTCMDOUTPUT*,
	and won't be visible (unless the *-v* option is present).
	The command's *stderr* output will NOT be redirected.
	*expectedReturnStatus* can be any number (0..255),
	or the special value `any`, in which case
	all return status values will be accepted
	(except 126 and 127, those are still considered a failure,
	because they usually signify a [shell command invocation error](http://www.tldp.org/LDP/abs/html/exitcodes.html)).

* <code><b>assertEq</b> valueActual valueExpected [errorMessage]</code>  
	This assertion compares two strings and tests them for equality.

* <code><b>assertContains</b> valueActual valueExpectedPart [errorMessage]</code>  
	This assertion compares two strings,
	expecting the second to be contained somewhere in the first.

* <code><b>assertRegex</b> valueActual regex [errorMessage]</code>  
	This assertion checks whether the *regex* (PCRE regular expression)
	matches the *valueActual* string.
	The regex argument must be enclosed by slashes,
	can start with a `!` to negate the matching sense,
	and can end with `i`/`m`/`s` modifier(s).

* <code><b>assertEmpty</b> valueActual [errorMessage]</code>  
	This assertion tests a string, expecting it to be empty.

* <code><b>assertCmdEq</b> command expectedOutput [errorMessage]</code>  
	This assertion is a combination of *assertCmd*+*assertEq*.
	It executes a command, then compares its entire *stdout* output against *expectedOutput*.
	The command is expected to always have a return status of zero.

* <code><b>assertCmdEmpty</b> command [errorMessage]</code>  
	This assertion is a combination of *assertCmd*+*assertEmpty*.
	It executes a command, then compares its entire *stdout* output against the empty string.
	The command is expected to always have a return status of zero.

* <code><b>assertFileSize</b> fileName expectedSize [errorMessage]</code>  
	This assertion checks than a file exists and compares its total size (in bytes) against *expectedSize*.

* <code><b>assertFileMode</b> fileName expectedOctalMode [errorMessage]</code>  
	This assertion checks that a file exists and compares its octal access mode
	(as printed by “*stat -c %a*”, e.g. *755*)
	against *expectedOctalMode*.

* <code><b>assertSubshellWasExecuted</b> [errorMessage]</code>  
	This assertion checks whether the last subshell script created via *prepare\_subshell()* has been executed.
	It does so by checking the existence of the marker file which the subshell script should have created.
	See “[Subshell Testing][subshells]”.


# Project configuration

If your project needs some extra configuration for all or most of its tests,
create a file called *config.sh* in the same directory as the test scripts.
*init.sh* will automatically source that file if it exists.

This is the place to define additional helper variables and functions used across multiple tests,
override hook functions,
and to build custom assertion functions.
If most of your tests run the same binary,
it might be handy to define a variable with the binary's path in the *config.sh* file.


# Writing custom assertions

You can easily build new assertion functions
which may of course use framework assertions functions
and/or shell built-ins
and/or the framework's helper functions such as *fail()*.

If you use them in one test script only, put them there;
if several of your test scripts use them,
put them in your project's [config.sh](#project-configuration) file.

#### Assertion counter

All assertion functions provided by this framework
increase the *$ASSERTCNT* variable by 1.

So if a custom assertion function
only calls one framework assertion,
the counter will be correct.

In all other cases you may use
the [addAssertionCount()](#helper-functions) helper function
to correct to counter.

Alternatively,
set the *SKIP\_ASSERTCNT* variable
to some non-empty value;
it will disable *addAssertionCount()* completely,
even for the framework-provided assertions.

#### Example

```bash
assertAbsolutePathExists () {
    addAssertionCount +1
    local SKIP_ASSERTCNT=yes  # this prevents builtin assertions from increasing $ASSERTCNT.
    assertRegex "$1" "/^\//" \
        "The argument is not an absolute path."
    assertRegex "$1" "!/\/\.\.?\//" \
        "The argument is not a canonical path as it contains '.' or '..' components."
    [ -e "$1" ] || fail \
        "Path does not exist: '$1'"
}
```


# Helper variables

*init.sh* also provides these environment variables:

* **$THIS**, the full path of the currently-running test script.  
	Example: `/home/mle/project-x/test/00-test-compile.sh`

* **$TESTNAME**, the current test script name (without its *.sh* suffix).  
	Example: `00-test-compile`

* **$HERE**, the directory where the current test script is located.  
	Example: `/home/mle/project-x/test`

* **$ASSERTSH**, the full path of the *assert.sh* script file, which has already been sourced by *init.sh*.

* **$ASSERTCNT**, the number of assertions performed so far.
    Starts at zero.
    Can be changed manually or with [addAssertionCount()](#helper-functions).

* **$SKIP\_ASSERTCNT**, set to the empty string.
    You can set this to a non-empty string to prevent addAssertionCount() from doing anything,
    e.g. inside custom assertions.


# Helper functions

*init.sh* also provides these helper functions:

* <code><b>success</b></code>  
	This function prints a green “*Success: $TESTNAME*” line,
	performs some cleanup,
	and ends the test script with exit status zero.
	Call it at the end of every test script!

* <code><b>fail</b> errorMessage</code>  
	This function prints an error message in red on *stderr*,
	performs some cleanup,
	and ends the test script with exit status 99.
	This can be used for one-line mini-assertions:  
	`[ -x binfile ] || fail "binfile not found or not executable!"`

* <code><b>err</b> errorMessage</code>  
	This function prints an error message in red on *stderr*
	(like *fail()*),
	but does NOT abort the test script.
	Use it if you want to print multi-line error messages before calling *fail()*.

* <code><b>skip</b> [errorMessage]</code>  
	This function prints an error message in yellow on *stderr*
	and stops the test script,
	but with exit status zero (success).
	Use this, for example, if a precondition of your test script was not met
	and you don't consider that an actual test failure.

* <code><b>cd\_tmpdir</b></code>  
	Creates a temporary directory to work in and changes into it.
	Use this if your test script wants to create some files/directories.
	The temporary directory will be automatically removed when the test script ends,
	provided it is empty.


* <code><b>add\_cleanup</b> filename...</code>  
	Adds one or more filenames to the *$CLEANUP\_FILES* list.
	Use this if your test script creates files in the temporary directory
	which should be automatically deleted as soon as the test script ends.
	Be careful, they'll be deleted with “rm -fd” and must not contain spaces.

* <code><b>addAssertionCount</b> [count]</code>  
        Adds a number to the *$ASSERTCNT* env var.
        The default number argument is `+1`.
        The argument may be negative.
        This may be useful if you want to implement custom assertion functions.


# Hook functions

All available hook functions are empty stub functions defined in *init.sh*.
Override them in your test script or in your *config.sh* as necessary.

* **hook\_cleanup()**, called on cleanup, i.e. when the test script ends (either because of a failed assertion or because it called *success()*). Use this instead of *add\_cleanup()* if your test script needs to do some serious cleanup, especially if it might need to remove files with spaces in their names (which would not be safe for *add\_cleanup()*, as its *$CLEANUP\_FILES* list is space-delimited).


# Author

Maximilian Eul
\<[maximilian@eul.cc](mailto:maximilian@eul.cc)\>

https://github.com/mle86/sh-tests

