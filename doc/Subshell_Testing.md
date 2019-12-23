# Sub-Shell Testing

To test a command which runs another command
the usual approach is to have a helper script and supply that as the subcommand.
If the subcommand script should be able to perform its own *assert.sh* assertions
it'll have to include that file by itself (the path is available in the *$ASSERTSH* env var).

The test framework offers the *prepare\_subshell()* function to aid this process:
The function will create a new, randomly-named script file,
fill it with some initialization calls,
and append its *stdin* input.

Initialization done by all subshell scripts created by *prepare\_subshell()*:

1. Sets env var *$IN\_SUBSHELL=yes*,
1. creates a randomized marker file so that *assertSubshellWasExecuted()* will succeed,
1. includes the *assert.sh* script so that all assertion functions as well as *fail()* and *err()* are available,
1. redefines *cleanup()* and *success()* as they should not do anything inside a subshell,
1. includes the *config.sh* script (if it exists).

The filname of the new script file is stored in the *$TMPSH* and *$SHELL* env vars.
This can be useful to test commands which don't take a subcommand argument but simply start a new interactive shell.

*prepare\_subshell()* requires a prior *cd\_tmpdir()* call,
because it'll refuse to create the subshell script in the test root.


## Example

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


