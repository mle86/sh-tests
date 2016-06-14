#!/bin/sh
. $(dirname "$0")/init.sh
. $(dirname "$0")/helpers.sh

# This tests whether the assertCmdEmpty() assertion function works correctly.

# Successful cases:
test_assertion 'pass' assertCmdEmpty ""
test_assertion 'pass' assertCmdEmpty ":;"
test_assertion 'pass' assertCmdEmpty "true"
test_assertion 'pass' assertCmdEmpty "echo -n \"\""

# Special case: trailing newlines are always removed
test_assertion 'pass' assertCmdEmpty "/bin/echo -e \"\n\n\n\"" \
	|| fail "assertCmdEmpty considered several newlines as not empty!"

# Commands with output:
test_assertion 'fail' assertCmdEmpty "echo yyyy"
test_assertion 'fail' assertCmdEmpty "echo yyyy ; true"

# Commands with a non-zero exit status:
test_assertion 'fail' assertCmdEmpty "false"
test_assertion 'fail' assertCmdEmpty "true ; false"

# Both:
test_assertion 'fail' assertCmdEmpty "echo yyyy ; false"

success
