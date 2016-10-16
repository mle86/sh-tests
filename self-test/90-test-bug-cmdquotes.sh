#!/bin/sh
. $(dirname "$0")/init.sh
. $(dirname "$0")/helpers.sh

# The assertCmd() function contained a problem:
# Because the command string was passed to "sh -s" with a plain "echo",
# some escape sequences in the input got evaluated,
# resulting in unexpected behavior.
# 
# The command passing is now done with "printf %s", which should fix all problems of this kind.
# 
# This test verifies that the fix is effective.


t_expected='foo"bar'
test_assertion 'pass'  assertCmdEq "echo 'foo\"bar' | cat -v" "$t_expected"  \
	|| fail "assertCmd() with properly-escaped double-quote in command did not work correctly!"

t_expected="foo'bar\"zog"
test_assertion 'pass'  assertCmdEq "echo \"foo'bar\\\"zog\" | cat -v" "$t_expected"  \
	|| fail "assertCmd() with properly-escaped single- and double-quotes in command did not work correctly!"


# "cat -v" transforms NUL into "^@":
t_expected="aa;b^@b;cc"

test_assertion 'pass'  assertCmdEq "printf 'aa;b\\''000b;cc' | cat -v" "$t_expected"  \
	|| fail "assertCmd() with legacy escaped-NUL quoting trick did not work properly!"

test_assertion 'pass'  assertCmdEq "printf 'aa;b\\000b;cc' | cat -v" "$t_expected"  \
	|| fail "assertCmd() command with propery-quoted NUL did not work correctly!"


t_actual="aa;b^@x;cc"

test_assertion 'fail'  assertCmdEq "printf 'aa;b\\''000x;cc' | cat -v" "$t_expected"  \
	|| fail "assertCmd() with legacy escaped-NUL quoting trick did not work properly!"

test_assertion 'fail'  assertCmdEq "printf 'aa;b\\000x;cc' | cat -v" "$t_expected"  \
	|| fail "assertCmd() command with propery-quoted NUL did not work correctly!"


success
